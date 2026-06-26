using System.Data;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Models.Wallet;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Wallet;

public class WalletService : IWalletService
{
    private readonly ApplicationDbContext _context;
    private readonly IWalletPaymentSettingsRepository _settingsRepository;
    private readonly IWalletCardPaymentGateway _cardPaymentGateway;
    private readonly IBookingWalletService _bookingWalletService;

    public WalletService(
        ApplicationDbContext context,
        IWalletPaymentSettingsRepository settingsRepository,
        IWalletCardPaymentGateway cardPaymentGateway,
        IBookingWalletService bookingWalletService)
    {
        _context = context;
        _settingsRepository = settingsRepository;
        _cardPaymentGateway = cardPaymentGateway;
        _bookingWalletService = bookingWalletService;
    }

    public async Task<WalletSummaryDTO> GetWalletSummaryAsync(int customerId, CancellationToken cancellationToken = default)
    {
        var wallet = await GetOrCreateWalletEntityAsync(customerId, cancellationToken);
        var settings = await _settingsRepository.GetOrCreateAsync(cancellationToken);
        return MapSummary(wallet, settings);
    }

    public async Task<PagedResult<WalletTransactionDTO>> GetTransactionsAsync(
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var (page, pageSize, skip) = pagination.Normalize();
        var query = _context.WalletTransactions.AsNoTracking()
            .Where(t => t.CustomerId == customerId)
            .OrderByDescending(t => t.CreatedAt);

        var totalCount = await query.CountAsync(cancellationToken);
        var rows = await query.Skip(skip).Take(pageSize).ToListAsync(cancellationToken);
        return PagedResult<WalletTransactionDTO>.Create(rows.Select(MapTransaction).ToList(), page, pageSize, totalCount);
    }

    public async Task<WalletTopUpDTO> CreateTopUpAsync(
        int customerId,
        CreateWalletTopUpDTO dto,
        CancellationToken cancellationToken = default)
    {
        ValidateTopUpAmount(dto.RequestedAmount);
        var method = NormalizeTopUpMethod(dto.PaymentMethod);

        if (method == WalletPaymentMethods.BankTransfer)
        {
            var hasActiveAccount = await _context.BankTransferAccounts
                .AnyAsync(a => a.IsActive, cancellationToken);
            if (!hasActiveAccount)
                throw new InvalidOperationException("Bank transfer is not available. No active bank account configured.");
        }

        var wallet = await GetOrCreateWalletEntityAsync(customerId, cancellationToken);
        var transactionType = method == WalletPaymentMethods.BankCard
            ? WalletTransactionTypes.BankCardTopUp
            : WalletTransactionTypes.BankTransferTopUp;

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var topUp = new WalletTopUpRequest
            {
                CustomerId = customerId,
                WalletId = wallet.Id,
                RequestedAmount = dto.RequestedAmount,
                PaymentMethod = method,
                Status = WalletTopUpStatuses.Pending,
                TransferReferenceNumber = dto.TransferReferenceNumber?.Trim(),
                TransferReceiptImageUrl = dto.TransferReceiptImageUrl?.Trim(),
                Notes = dto.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };
            _context.WalletTopUpRequests.Add(topUp);
            await _context.SaveChangesAsync(cancellationToken);

            var ledger = new WalletTransaction
            {
                WalletId = wallet.Id,
                CustomerId = customerId,
                Amount = dto.RequestedAmount,
                Type = transactionType,
                Direction = WalletTransactionDirections.Credit,
                Status = WalletTransactionStatuses.Pending,
                PaymentMethod = method,
                Notes = dto.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(ledger);
            await _context.SaveChangesAsync(cancellationToken);

            topUp.WalletTransactionId = ledger.Id;
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return MapTopUp(topUp);
        });
    }

    public async Task<WalletTopUpDTO?> GetTopUpAsync(int customerId, int topUpId, CancellationToken cancellationToken = default)
    {
        var topUp = await _context.WalletTopUpRequests.AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == topUpId && r.CustomerId == customerId, cancellationToken);
        return topUp == null ? null : MapTopUp(topUp);
    }

    public async Task<BankTransferAccountDTO?> GetActiveBankTransferAccountForCustomerAsync(
        CancellationToken cancellationToken = default)
    {
        var account = await _context.BankTransferAccounts.AsNoTracking()
            .FirstOrDefaultAsync(a => a.IsActive, cancellationToken);
        return account == null ? null : MapBankAccount(account);
    }

    public async Task<WalletTopUpDTO> ConfirmBankCardTopUpAsync(
        int topUpId,
        ConfirmBankCardTopUpDTO dto,
        CancellationToken cancellationToken = default)
    {
        var paymentReference = dto.PaymentReference.Trim();
        if (string.IsNullOrEmpty(paymentReference))
            throw new ArgumentException("Payment reference is required.");

        var existingByRef = await _context.WalletTopUpRequests.AsNoTracking()
            .FirstOrDefaultAsync(
                r => r.GatewayPaymentReference == paymentReference
                    && r.Status == WalletTopUpStatuses.Completed,
                cancellationToken);
        if (existingByRef != null)
            return MapTopUp(existingByRef);

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var topUp = await _context.WalletTopUpRequests
                .FirstOrDefaultAsync(r => r.Id == topUpId, cancellationToken)
                ?? throw new InvalidOperationException("Top-up request not found.");

            if (topUp.PaymentMethod != WalletPaymentMethods.BankCard)
                throw new InvalidOperationException("Only bank card top-ups can be confirmed through this flow.");

            if (topUp.Status == WalletTopUpStatuses.Completed)
                return MapTopUp(topUp);

            if (topUp.Status != WalletTopUpStatuses.Pending)
                throw new InvalidOperationException("Top-up request is not pending.");

            var duplicateRef = await _context.WalletTopUpRequests
                .AnyAsync(r => r.GatewayPaymentReference == paymentReference && r.Id != topUpId, cancellationToken);
            if (duplicateRef)
                throw new InvalidOperationException("Payment reference already used.");

            await CreditWalletForTopUpAsync(
                topUp,
                topUp.RequestedAmount,
                paymentReference,
                WalletTopUpStatuses.Completed,
                WalletTransactionStatuses.Completed,
                reviewedByAdminId: null,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return MapTopUp(topUp);
        });
    }

    public async Task<WalletTopUpDTO> FailBankCardTopUpAsync(
        int topUpId,
        FailBankCardTopUpDTO? dto,
        CancellationToken cancellationToken = default)
    {
        var topUp = await _context.WalletTopUpRequests
            .FirstOrDefaultAsync(r => r.Id == topUpId, cancellationToken)
            ?? throw new InvalidOperationException("Top-up request not found.");

        if (topUp.PaymentMethod != WalletPaymentMethods.BankCard)
            throw new InvalidOperationException("Only bank card top-ups can be failed through this flow.");

        if (topUp.Status == WalletTopUpStatuses.Completed)
            throw new InvalidOperationException("Completed top-up cannot be marked as failed.");

        if (topUp.Status == WalletTopUpStatuses.Failed)
            return MapTopUp(topUp);

        topUp.Status = WalletTopUpStatuses.Failed;
        topUp.RejectionReason = dto?.Reason?.Trim();
        topUp.CompletedAt = DateTime.UtcNow;

        if (topUp.WalletTransactionId.HasValue)
        {
            var ledger = await _context.WalletTransactions
                .FirstAsync(t => t.Id == topUp.WalletTransactionId.Value, cancellationToken);
            ledger.Status = WalletTransactionStatuses.Failed;
            ledger.CompletedAt = DateTime.UtcNow;
            ledger.Notes = dto?.Reason?.Trim();
        }

        await _context.SaveChangesAsync(cancellationToken);
        return MapTopUp(topUp);
    }

    public async Task<PagedResult<WalletTopUpDTO>> GetBankTransferTopUpsForAdminAsync(
        string? status,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var (page, pageSize, skip) = pagination.Normalize();
        var query = _context.WalletTopUpRequests.AsNoTracking()
            .Where(r => r.PaymentMethod == WalletPaymentMethods.BankTransfer);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(r => r.Status == status);

        query = query.OrderByDescending(r => r.CreatedAt);
        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query.Skip(skip).Take(pageSize).ToListAsync(cancellationToken);
        return PagedResult<WalletTopUpDTO>.Create(items.Select(MapTopUp).ToList(), page, pageSize, totalCount);
    }

    public async Task<WalletTopUpDTO> GetBankTransferTopUpByIdForAdminAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var topUp = await _context.WalletTopUpRequests.AsNoTracking()
            .FirstOrDefaultAsync(
                r => r.Id == id && r.PaymentMethod == WalletPaymentMethods.BankTransfer,
                cancellationToken)
            ?? throw new InvalidOperationException("Bank transfer top-up not found.");
        return MapTopUp(topUp);
    }

    public async Task<WalletTopUpDTO> ApproveBankTransferTopUpAsync(
        int topUpId,
        int adminUserId,
        ApproveBankTransferTopUpDTO dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.ApprovedAmount <= 0)
            throw new ArgumentOutOfRangeException(nameof(dto.ApprovedAmount));

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var topUp = await _context.WalletTopUpRequests
                .FirstOrDefaultAsync(r => r.Id == topUpId, cancellationToken)
                ?? throw new InvalidOperationException("Top-up request not found.");

            if (topUp.PaymentMethod != WalletPaymentMethods.BankTransfer)
                throw new InvalidOperationException("Only bank transfer top-ups can be approved through this flow.");

            if (topUp.Status == WalletTopUpStatuses.Approved)
                return MapTopUp(topUp);

            if (topUp.Status != WalletTopUpStatuses.Pending)
                throw new InvalidOperationException("Top-up request is not pending.");

            topUp.ApprovedAmount = dto.ApprovedAmount;
            topUp.AdminNotes = dto.AdminNotes?.Trim();

            await CreditWalletForTopUpAsync(
                topUp,
                dto.ApprovedAmount,
                topUp.TransferReferenceNumber,
                WalletTopUpStatuses.Approved,
                WalletTransactionStatuses.Completed,
                adminUserId,
                cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return MapTopUp(topUp);
        });
    }

    public async Task<WalletTopUpDTO> RejectBankTransferTopUpAsync(
        int topUpId,
        int adminUserId,
        RejectBankTransferTopUpDTO dto,
        CancellationToken cancellationToken = default)
    {
        var topUp = await _context.WalletTopUpRequests
            .FirstOrDefaultAsync(r => r.Id == topUpId, cancellationToken)
            ?? throw new InvalidOperationException("Top-up request not found.");

        if (topUp.PaymentMethod != WalletPaymentMethods.BankTransfer)
            throw new InvalidOperationException("Only bank transfer top-ups can be rejected through this flow.");

        if (topUp.Status == WalletTopUpStatuses.Approved)
            throw new InvalidOperationException("Approved top-up cannot be rejected.");

        if (topUp.Status == WalletTopUpStatuses.Rejected)
            return MapTopUp(topUp);

        topUp.Status = WalletTopUpStatuses.Rejected;
        topUp.RejectionReason = dto.Reason.Trim();
        topUp.AdminNotes = dto.Reason.Trim();
        topUp.ReviewedByAdminId = adminUserId;
        topUp.ReviewedAt = DateTime.UtcNow;

        if (topUp.WalletTransactionId.HasValue)
        {
            var ledger = await _context.WalletTransactions
                .FirstAsync(t => t.Id == topUp.WalletTransactionId.Value, cancellationToken);
            ledger.Status = WalletTransactionStatuses.Rejected;
            ledger.CompletedAt = DateTime.UtcNow;
            ledger.Notes = dto.Reason.Trim();
        }

        await _context.SaveChangesAsync(cancellationToken);
        return MapTopUp(topUp);
    }

    public async Task<IReadOnlyList<BankTransferAccountDTO>> GetBankAccountsAsync(
        CancellationToken cancellationToken = default)
    {
        var accounts = await _context.BankTransferAccounts.AsNoTracking()
            .OrderByDescending(a => a.IsActive)
            .ThenByDescending(a => a.UpdatedAt)
            .ToListAsync(cancellationToken);
        return accounts.Select(MapBankAccount).ToList();
    }

    public async Task<BankTransferAccountDTO> CreateBankAccountAsync(
        CreateBankTransferAccountDTO dto,
        CancellationToken cancellationToken = default)
    {
        var account = new BankTransferAccount
        {
            BankName = dto.BankName.Trim(),
            AccountHolderName = dto.AccountHolderName.Trim(),
            AccountNumber = dto.AccountNumber.Trim(),
            Iban = dto.Iban?.Trim(),
            BranchName = dto.BranchName?.Trim(),
            Instructions = dto.Instructions?.Trim(),
            IsActive = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _context.BankTransferAccounts.Add(account);
        await _context.SaveChangesAsync(cancellationToken);
        return MapBankAccount(account);
    }

    public async Task<BankTransferAccountDTO> UpdateBankAccountAsync(
        int id,
        UpdateBankTransferAccountDTO dto,
        CancellationToken cancellationToken = default)
    {
        var account = await _context.BankTransferAccounts.FindAsync([id], cancellationToken)
            ?? throw new InvalidOperationException("Bank account not found.");

        account.BankName = dto.BankName.Trim();
        account.AccountHolderName = dto.AccountHolderName.Trim();
        account.AccountNumber = dto.AccountNumber.Trim();
        account.Iban = dto.Iban?.Trim();
        account.BranchName = dto.BranchName?.Trim();
        account.Instructions = dto.Instructions?.Trim();
        account.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(cancellationToken);
        return MapBankAccount(account);
    }

    public async Task<BankTransferAccountDTO> ActivateBankAccountAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var accounts = await _context.BankTransferAccounts.ToListAsync(cancellationToken);
            foreach (var a in accounts)
                a.IsActive = a.Id == id;

            var target = accounts.FirstOrDefault(a => a.Id == id)
                ?? throw new InvalidOperationException("Bank account not found.");

            target.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return MapBankAccount(target);
        });
    }

    public async Task<BankTransferAccountDTO> DeactivateBankAccountAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var account = await _context.BankTransferAccounts.FindAsync([id], cancellationToken)
            ?? throw new InvalidOperationException("Bank account not found.");

        account.IsActive = false;
        account.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(cancellationToken);
        return MapBankAccount(account);
    }

    public async Task<WalletTransactionDTO> CreditCustomerWalletAsync(
        int customerId,
        int adminUserId,
        AdminManualWalletCreditDTO dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Amount <= 0)
            throw new ArgumentOutOfRangeException(nameof(dto.Amount));

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var wallet = await GetOrCreateWalletEntityAsync(customerId, cancellationToken);
            wallet.Balance += dto.Amount;
            wallet.UpdatedAt = DateTime.UtcNow;

            var ledger = new WalletTransaction
            {
                WalletId = wallet.Id,
                CustomerId = customerId,
                Amount = dto.Amount,
                Type = WalletTransactionTypes.ManualCredit,
                Direction = WalletTransactionDirections.Credit,
                Status = WalletTransactionStatuses.Completed,
                PaymentMethod = WalletPaymentMethods.Wallet,
                Notes = dto.Notes?.Trim(),
                CreatedByAdminId = adminUserId,
                CreatedAt = DateTime.UtcNow,
                CompletedAt = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(ledger);
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return MapTransaction(ledger);
        });
    }

    public async Task<BulkWalletCreditResultDTO> BulkCreditWalletsAsync(
        int adminUserId,
        AdminBulkWalletCreditDTO dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Amount <= 0)
            throw new ArgumentOutOfRangeException(nameof(dto.Amount));

        var customerIds = dto.CustomerIds.Distinct().ToList();
        if (customerIds.Count == 0)
            throw new ArgumentException("At least one customer id is required.");

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var credited = new List<int>();
            foreach (var customerId in customerIds)
            {
                var wallet = await GetOrCreateWalletEntityAsync(customerId, cancellationToken);
                wallet.Balance += dto.Amount;
                wallet.UpdatedAt = DateTime.UtcNow;

                _context.WalletTransactions.Add(new WalletTransaction
                {
                    WalletId = wallet.Id,
                    CustomerId = customerId,
                    Amount = dto.Amount,
                    Type = WalletTransactionTypes.ManualCredit,
                    Direction = WalletTransactionDirections.Credit,
                    Status = WalletTransactionStatuses.Completed,
                    PaymentMethod = WalletPaymentMethods.Wallet,
                    Notes = dto.Notes?.Trim(),
                    CreatedByAdminId = adminUserId,
                    CreatedAt = DateTime.UtcNow,
                    CompletedAt = DateTime.UtcNow
                });
                credited.Add(customerId);
            }

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return new BulkWalletCreditResultDTO
            {
                SuccessCount = credited.Count,
                CreditedCustomerIds = credited,
                Message = $"Credited {credited.Count} wallet(s) successfully."
            };
        });
    }

    public async Task<WalletPaymentSettingsDTO> GetPaymentSettingsAsync(CancellationToken cancellationToken = default)
    {
        var settings = await _settingsRepository.GetOrCreateAsync(cancellationToken);
        return MapSettings(settings);
    }

    public async Task<WalletPaymentSettingsDTO> UpdatePaymentSettingsAsync(
        UpdateWalletPaymentSettingsDTO dto,
        int adminUserId,
        CancellationToken cancellationToken = default)
    {
        if (dto.WalletPaymentFeePercentage is < 0 or > 100)
            throw new ArgumentOutOfRangeException(nameof(dto.WalletPaymentFeePercentage));

        var updated = await _settingsRepository.UpdateAsync(
            dto.IsWalletPaymentEnabled,
            dto.WalletPaymentFeePercentage,
            adminUserId,
            cancellationToken);
        return MapSettings(updated);
    }

    public async Task<WalletBookingPaymentQuoteDTO> GetBookingPaymentQuoteAsync(
        int customerId,
        decimal bookingTotal,
        CancellationToken cancellationToken = default)
    {
        var wallet = await GetOrCreateWalletEntityAsync(customerId, cancellationToken);
        var settings = await _settingsRepository.GetOrCreateAsync(cancellationToken);
        var (walletFee, required) = WalletFeeCalculator.Calculate(bookingTotal, settings.WalletPaymentFeePercentage);

        return new WalletBookingPaymentQuoteDTO
        {
            BookingTotal = bookingTotal,
            WalletFee = walletFee,
            RequiredAmount = required,
            WalletBalance = wallet.Balance,
            IsWalletPaymentEnabled = settings.IsWalletPaymentEnabled,
            HasSufficientBalance = wallet.Balance >= required
        };
    }

    public Task<WalletBookingPaymentResultDTO> ProcessBookingWalletPaymentAsync(
        int customerId,
        int bookingId,
        decimal bookingTotal,
        CancellationToken cancellationToken = default) =>
        _bookingWalletService.ReserveBookingWalletPaymentAsync(customerId, bookingId, bookingTotal, cancellationToken);

    public async Task<BankCardTopUpStartResponseDTO> StartBankCardTopUpAsync(
        int customerId,
        decimal amount,
        CancellationToken cancellationToken = default)
    {
        ValidateTopUpAmount(amount);
        var wallet = await GetOrCreateWalletEntityAsync(customerId, cancellationToken);
        var gatewayReference = $"WTU-{Guid.NewGuid():N}";

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            var topUp = new WalletTopUpRequest
            {
                CustomerId = customerId,
                WalletId = wallet.Id,
                RequestedAmount = amount,
                PaymentMethod = WalletPaymentMethods.BankCard,
                Status = WalletTopUpStatuses.Pending,
                GatewayPaymentReference = gatewayReference,
                CreatedAt = DateTime.UtcNow
            };
            _context.WalletTopUpRequests.Add(topUp);
            await _context.SaveChangesAsync(cancellationToken);

            var ledger = new WalletTransaction
            {
                WalletId = wallet.Id,
                CustomerId = customerId,
                Amount = amount,
                Type = WalletTransactionTypes.BankCardTopUp,
                Direction = WalletTransactionDirections.Credit,
                Status = WalletTransactionStatuses.Pending,
                PaymentMethod = WalletPaymentMethods.BankCard,
                ReferenceNumber = gatewayReference,
                CreatedAt = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(ledger);
            await _context.SaveChangesAsync(cancellationToken);

            topUp.WalletTransactionId = ledger.Id;
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return new BankCardTopUpStartResponseDTO
            {
                TopUpId = topUp.Id,
                GatewayPaymentReference = gatewayReference,
                Amount = amount,
                PaymentUrl = _cardPaymentGateway.BuildPaymentUrl(topUp.Id, gatewayReference, amount)
            };
        });
    }

    public async Task<WalletTopUpDTO> CreateBankTransferTopUpAsync(
        int customerId,
        CreateWalletTopUpDTO dto,
        CancellationToken cancellationToken = default)
    {
        dto.PaymentMethod = WalletPaymentMethods.BankTransfer;
        return await CreateTopUpAsync(customerId, dto, cancellationToken);
    }

    public async Task<WalletTopUpCallbackResponseDTO> ProcessWalletTopUpCallbackAsync(
        WalletTopUpCallbackRequestDTO dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.Success)
        {
            await ConfirmBankCardTopUpAsync(
                dto.TopUpId,
                new ConfirmBankCardTopUpDTO { PaymentReference = dto.PaymentReference },
                cancellationToken);

            var topUp = await _context.WalletTopUpRequests.AsNoTracking()
                .FirstAsync(r => r.Id == dto.TopUpId, cancellationToken);
            var wallet = await _context.Wallets.AsNoTracking()
                .FirstAsync(w => w.Id == topUp.WalletId, cancellationToken);

            return new WalletTopUpCallbackResponseDTO
            {
                Credited = true,
                TopUpId = dto.TopUpId,
                Status = topUp.Status,
                NewWalletBalance = wallet.Balance,
                Message = "Wallet credited successfully."
            };
        }

        await FailBankCardTopUpAsync(
            dto.TopUpId,
            new FailBankCardTopUpDTO { Reason = dto.FailureReason },
            cancellationToken);

        return new WalletTopUpCallbackResponseDTO
        {
            Credited = false,
            TopUpId = dto.TopUpId,
            Status = WalletTopUpStatuses.Failed,
            Message = dto.FailureReason ?? "Payment failed."
        };
    }

    public async Task<WalletTopUpCallbackResponseDTO> TestInstantBankCardTopUpAsync(
        int customerId,
        decimal amount,
        CancellationToken cancellationToken = default)
    {
        var start = await StartBankCardTopUpAsync(customerId, amount, cancellationToken);
        return await ProcessWalletTopUpCallbackAsync(
            new WalletTopUpCallbackRequestDTO
            {
                TopUpId = start.TopUpId,
                PaymentReference = start.GatewayPaymentReference,
                Success = true
            },
            cancellationToken);
    }

    public async Task ProcessBookingWalletRefundAsync(int bookingId, CancellationToken cancellationToken = default)
    {
        var payment = await _context.Payments
            .FirstOrDefaultAsync(
                p => p.BookingId == bookingId && p.PaymentMethod == WalletPaymentMethods.Wallet,
                cancellationToken);

        if (payment == null || payment.PaymentStatus != PaymentStatuses.Paid)
            return;

        if (payment.WalletRefundStatus == WalletRefundStatuses.Refunded)
            return;

        var existingRefund = await _context.WalletTransactions.AnyAsync(
            t => t.BookingId == bookingId
                && t.Type == WalletTransactionTypes.WalletRefund
                && t.Status == WalletTransactionStatuses.Completed,
            cancellationToken);
        if (existingRefund)
        {
            payment.WalletRefundStatus = WalletRefundStatuses.Refunded;
            await _context.SaveChangesAsync(cancellationToken);
            return;
        }

        var booking = await _context.Bookings.AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken);
        if (booking == null)
            return;

        var strategy = _context.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.BookingId == bookingId && p.PaymentMethod == WalletPaymentMethods.Wallet, cancellationToken);
            if (payment == null || payment.WalletRefundStatus == WalletRefundStatuses.Refunded)
            {
                await transaction.CommitAsync(cancellationToken);
                return;
            }

            var wallet = await _context.Wallets
                .FirstOrDefaultAsync(w => w.CustomerId == booking.UserId, cancellationToken);
            if (wallet == null)
                throw new InvalidOperationException("Customer wallet not found for refund.");

            wallet.Balance += payment.Amount;
            wallet.UpdatedAt = DateTime.UtcNow;

            _context.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                CustomerId = booking.UserId,
                BookingId = bookingId,
                Amount = payment.Amount,
                Type = WalletTransactionTypes.WalletRefund,
                Direction = WalletTransactionDirections.Credit,
                Status = WalletTransactionStatuses.Completed,
                PaymentMethod = WalletPaymentMethods.Wallet,
                Notes = "Booking refund",
                CreatedAt = DateTime.UtcNow,
                CompletedAt = DateTime.UtcNow
            });

            payment.WalletRefundStatus = WalletRefundStatuses.Refunded;
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        });
    }

    public async Task<Models.Wallet.Wallet> GetOrCreateWalletEntityAsync(int customerId, CancellationToken cancellationToken = default)
    {
        var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.CustomerId == customerId, cancellationToken);
        if (wallet != null)
            return wallet;

        wallet = new Models.Wallet.Wallet
        {
            CustomerId = customerId,
            Balance = 0,
            Currency = "LYD",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _context.Wallets.Add(wallet);
        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return await _context.Wallets.FirstAsync(w => w.CustomerId == customerId, cancellationToken);
        }

        return wallet;
    }

    private async Task CreditWalletForTopUpAsync(
        WalletTopUpRequest topUp,
        decimal creditAmount,
        string? referenceNumber,
        string topUpStatus,
        string ledgerStatus,
        int? reviewedByAdminId,
        CancellationToken cancellationToken)
    {
        var wallet = await _context.Wallets
            .FirstAsync(w => w.Id == topUp.WalletId, cancellationToken);

        wallet.Balance += creditAmount;
        wallet.UpdatedAt = DateTime.UtcNow;

        topUp.Status = topUpStatus;
        topUp.GatewayPaymentReference = topUp.PaymentMethod == WalletPaymentMethods.BankCard
            ? referenceNumber?.Trim()
            : topUp.GatewayPaymentReference;
        topUp.CompletedAt = DateTime.UtcNow;
        topUp.ReviewedByAdminId = reviewedByAdminId;
        topUp.ReviewedAt = reviewedByAdminId.HasValue ? DateTime.UtcNow : topUp.ReviewedAt;

        if (topUp.WalletTransactionId.HasValue)
        {
            var ledger = await _context.WalletTransactions
                .FirstAsync(t => t.Id == topUp.WalletTransactionId.Value, cancellationToken);
            ledger.Amount = creditAmount;
            ledger.Status = ledgerStatus;
            ledger.ReferenceNumber = referenceNumber?.Trim();
            ledger.CompletedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync(cancellationToken);
    }

    private static void ValidateTopUpAmount(decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentOutOfRangeException(nameof(amount), "Top-up amount must be greater than 0.");
    }

    private static string NormalizeTopUpMethod(string paymentMethod)
    {
        if (string.Equals(paymentMethod, WalletPaymentMethods.BankCard, StringComparison.OrdinalIgnoreCase))
            return WalletPaymentMethods.BankCard;
        if (string.Equals(paymentMethod, WalletPaymentMethods.BankTransfer, StringComparison.OrdinalIgnoreCase))
            return WalletPaymentMethods.BankTransfer;

        throw new ArgumentException("Payment method must be BankCard or BankTransfer. Cash is not allowed.");
    }

    private static WalletSummaryDTO MapSummary(Models.Wallet.Wallet wallet, WalletPaymentSettings settings) =>
        new()
        {
            WalletId = wallet.Id,
            CustomerId = wallet.CustomerId,
            Balance = wallet.Balance,
            ReservedBalance = wallet.ReservedBalance,
            AvailableBalance = wallet.Balance,
            Currency = wallet.Currency,
            IsActive = wallet.IsActive,
            IsWalletPaymentEnabled = settings.IsWalletPaymentEnabled,
            WalletPaymentFeePercentage = settings.WalletPaymentFeePercentage
        };

    private static WalletTransactionDTO MapTransaction(WalletTransaction t) =>
        new()
        {
            Id = t.Id,
            WalletId = t.WalletId,
            CustomerId = t.CustomerId,
            BookingId = t.BookingId,
            Amount = t.Amount,
            Type = t.Type,
            Direction = t.Direction,
            Status = t.Status,
            PaymentMethod = t.PaymentMethod,
            ReferenceNumber = t.ReferenceNumber,
            Notes = t.Notes,
            CreatedByAdminId = t.CreatedByAdminId,
            CreatedAt = t.CreatedAt,
            CompletedAt = t.CompletedAt
        };

    private static WalletTopUpDTO MapTopUp(WalletTopUpRequest r) =>
        new()
        {
            Id = r.Id,
            CustomerId = r.CustomerId,
            RequestedAmount = r.RequestedAmount,
            ApprovedAmount = r.ApprovedAmount,
            PaymentMethod = r.PaymentMethod,
            Status = r.Status,
            TransferReferenceNumber = r.TransferReferenceNumber,
            TransferReceiptImageUrl = r.TransferReceiptImageUrl,
            GatewayPaymentReference = r.GatewayPaymentReference,
            Notes = r.Notes,
            AdminNotes = r.AdminNotes,
            RejectionReason = r.RejectionReason,
            CreatedAt = r.CreatedAt,
            ReviewedAt = r.ReviewedAt,
            CompletedAt = r.CompletedAt
        };

    private static WalletPaymentSettingsDTO MapSettings(WalletPaymentSettings s) =>
        new()
        {
            IsWalletPaymentEnabled = s.IsWalletPaymentEnabled,
            WalletPaymentFeePercentage = s.WalletPaymentFeePercentage,
            UpdatedAt = s.UpdatedAt,
            UpdatedByAdminId = s.UpdatedByAdminId
        };

    private static BankTransferAccountDTO MapBankAccount(BankTransferAccount a) =>
        new()
        {
            Id = a.Id,
            BankName = a.BankName,
            AccountHolderName = a.AccountHolderName,
            AccountNumber = a.AccountNumber,
            Iban = a.Iban,
            BranchName = a.BranchName,
            Instructions = a.Instructions,
            IsActive = a.IsActive,
            CreatedAt = a.CreatedAt,
            UpdatedAt = a.UpdatedAt
        };
}

public class WalletPaymentException : Exception
{
    public WalletPaymentException(string message) : base(message) { }
}

public class InsufficientWalletBalanceException : Exception
{
    public decimal WalletBalance { get; }
    public decimal RequiredAmount { get; }

    public InsufficientWalletBalanceException(decimal walletBalance, decimal requiredAmount)
        : base("Insufficient wallet balance. Please charge your wallet to continue.")
    {
        WalletBalance = walletBalance;
        RequiredAmount = requiredAmount;
    }
}

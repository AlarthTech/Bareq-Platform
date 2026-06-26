using System.Data;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Models.Wallet;
using CleaningHouse_API.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Wallet;

public class BookingWalletService : IBookingWalletService
{
    private readonly ApplicationDbContext _context;
    private readonly IWalletPaymentSettingsRepository _settingsRepository;
    private readonly INotificationService _notificationService;

    public BookingWalletService(
        ApplicationDbContext context,
        IWalletPaymentSettingsRepository settingsRepository,
        INotificationService notificationService)
    {
        _context = context;
        _settingsRepository = settingsRepository;
        _notificationService = notificationService;
    }

    public async Task<WalletBookingPaymentResultDTO> ReserveBookingWalletPaymentAsync(
        int customerId,
        int bookingId,
        decimal bookingTotal,
        CancellationToken cancellationToken = default)
    {
        var settings = await _settingsRepository.GetOrCreateAsync(cancellationToken);
        if (!settings.IsWalletPaymentEnabled)
            throw new WalletPaymentException("Wallet payment is currently unavailable.");

        var (walletFee, requiredAmount) = WalletFeeCalculator.Calculate(
            bookingTotal,
            settings.WalletPaymentFeePercentage);

        return await ExecuteSerializableAsync(async cancellationToken =>
        {
            var booking = await _context.Bookings
                .FirstOrDefaultAsync(b => b.Id == bookingId && b.UserId == customerId, cancellationToken)
                ?? throw new WalletPaymentException("Booking not found.");

            if (booking.WalletAmountReserved)
                throw new WalletPaymentException("Wallet amount is already reserved for this booking.");

            var wallet = await _context.Wallets
                .FirstOrDefaultAsync(w => w.CustomerId == customerId, cancellationToken)
                ?? throw new WalletPaymentException("Wallet not found.");

            if (wallet.Balance < requiredAmount)
                throw new InsufficientWalletBalanceException(wallet.Balance, requiredAmount);

            var existingReserve = await _context.WalletTransactions.AnyAsync(
                t => t.BookingId == bookingId && t.Type == WalletTransactionTypes.WalletReserve,
                cancellationToken);
            if (existingReserve)
                throw new WalletPaymentException("Wallet reservation already exists for this booking.");

            wallet.Balance -= requiredAmount;
            wallet.ReservedBalance += requiredAmount;
            wallet.UpdatedAt = DateTime.UtcNow;

            _context.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                CustomerId = customerId,
                BookingId = bookingId,
                Amount = requiredAmount,
                Type = WalletTransactionTypes.WalletReserve,
                Direction = WalletTransactionDirections.Debit,
                Status = WalletTransactionStatuses.Completed,
                PaymentMethod = WalletPaymentMethods.Wallet,
                Notes = "Booking wallet hold",
                CreatedAt = DateTime.UtcNow,
                CompletedAt = DateTime.UtcNow
            });

            _context.Payments.Add(new Payment
            {
                BookingId = bookingId,
                PaymentMethod = WalletPaymentMethods.Wallet,
                Amount = requiredAmount,
                WalletFeeAmount = walletFee,
                BookingTotalAmount = bookingTotal,
                WalletRefundStatus = WalletRefundStatuses.None,
                PaymentStatus = PaymentStatuses.Pending,
                PaidAt = null,
                CreatedAt = DateTime.UtcNow
            });

            booking.WalletAmountReserved = true;
            booking.WalletAmountCaptured = false;
            booking.WalletCapturedAt = null;

            await _context.SaveChangesAsync(cancellationToken);

            return new WalletBookingPaymentResultDTO
            {
                Message = "Booking created. Wallet amount reserved until service completion.",
                BookingId = bookingId,
                BookingTotal = bookingTotal,
                WalletFee = walletFee,
                PaidAmount = requiredAmount,
                RemainingWalletBalance = wallet.Balance,
                WalletAmountReserved = true,
                WalletAmountCaptured = false
            };
        }, cancellationToken);
    }

    public async Task<BookingDTO> ConfirmWorkerArrivalAsync(
        int customerId,
        int bookingId,
        CancellationToken cancellationToken = default)
    {
        var dto = await ExecuteSerializableAsync(async cancellationToken =>
        {
            var booking = await _context.Bookings
                .FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken)
                ?? throw new InvalidOperationException("Booking not found.");

            if (booking.UserId != customerId)
                throw new UnauthorizedAccessException("You can only confirm arrival for your own booking.");

            if (booking.Status != BookingStatuses.OnTheWay)
                throw new InvalidOperationException("Arrival can only be confirmed when the booking is on the way.");

            if (booking.IsWorkerArrivalConfirmed)
                throw new InvalidOperationException("Worker arrival is already confirmed.");

            var isWallet = await IsWalletBookingAsync(bookingId, cancellationToken);
            if (isWallet)
            {
                if (!booking.WalletAmountReserved || booking.WalletAmountCaptured)
                    throw new InvalidOperationException("Wallet reservation is not valid for capture.");

                await CaptureReservedAmountCoreAsync(booking, cancellationToken);
            }

            booking.IsWorkerArrivalConfirmed = true;
            booking.WorkerArrivalConfirmedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync(cancellationToken);

            return await _context.Bookings.AsNoTracking()
                .ProjectToDto()
                .FirstAsync(b => b.Id == bookingId, cancellationToken);
        }, cancellationToken);

        await _notificationService.NotifyWorkerArrivalConfirmedAsync(bookingId, cancellationToken);
        return dto;
    }

    /// <summary>Caller should run inside an existing DB transaction when combined with other booking updates.</summary>
    public async Task ApplyBookingStatusWalletEffectsAsync(
        Booking booking,
        int previousStatus,
        int newStatus,
        CancellationToken cancellationToken = default)
    {
        if (!await IsWalletBookingAsync(booking.Id, cancellationToken))
            return;

        var tracked = await _context.Bookings.FirstAsync(b => b.Id == booking.Id, cancellationToken);

        if (newStatus is BookingStatuses.Canceled or BookingStatuses.Rejected)
        {
            if (tracked.WalletAmountReserved && !tracked.WalletAmountCaptured)
                await ReleaseReservedAmountCoreAsync(tracked, cancellationToken);
            else if (tracked.WalletAmountCaptured)
                await RefundCapturedAmountCoreAsync(tracked, cancellationToken);
        }
        else if (newStatus == BookingStatuses.Completed)
        {
            if (tracked.WalletAmountReserved && !tracked.WalletAmountCaptured)
                await CaptureReservedAmountCoreAsync(tracked, cancellationToken);
        }

        await _context.SaveChangesAsync(cancellationToken);
    }

    private async Task CaptureReservedAmountCoreAsync(Booking booking, CancellationToken cancellationToken)
    {
        if (booking.WalletAmountCaptured)
            return;

        if (!booking.WalletAmountReserved)
            return;

        var payment = await GetWalletPaymentAsync(booking.Id, cancellationToken);
        if (payment == null || payment.PaymentStatus == PaymentStatuses.Paid)
            return;

        var wallet = await _context.Wallets.FirstAsync(w => w.CustomerId == booking.UserId, cancellationToken);
        var amount = payment.Amount;

        if (wallet.ReservedBalance < amount)
            throw new InvalidOperationException("Reserved wallet balance is insufficient for capture.");

        wallet.ReservedBalance -= amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        _context.WalletTransactions.Add(new WalletTransaction
        {
            WalletId = wallet.Id,
            CustomerId = booking.UserId,
            BookingId = booking.Id,
            Amount = amount,
            Type = WalletTransactionTypes.WalletCapture,
            Direction = WalletTransactionDirections.Debit,
            Status = WalletTransactionStatuses.Completed,
            PaymentMethod = WalletPaymentMethods.Wallet,
            Notes = "Booking wallet capture",
            CreatedAt = DateTime.UtcNow,
            CompletedAt = DateTime.UtcNow
        });

        payment.PaymentStatus = PaymentStatuses.Paid;
        payment.PaidAt = DateTime.UtcNow;

        booking.WalletAmountCaptured = true;
        booking.WalletCapturedAt = DateTime.UtcNow;

        await _notificationService.NotifyWalletAmountCapturedAsync(booking.Id, cancellationToken);
    }

    private async Task ReleaseReservedAmountCoreAsync(Booking booking, CancellationToken cancellationToken)
    {
        if (!booking.WalletAmountReserved || booking.WalletAmountCaptured)
            return;

        var payment = await GetWalletPaymentAsync(booking.Id, cancellationToken);
        if (payment == null || payment.PaymentStatus == PaymentStatuses.Released)
            return;

        var existingRelease = await _context.WalletTransactions.AnyAsync(
            t => t.BookingId == booking.Id && t.Type == WalletTransactionTypes.WalletRelease,
            cancellationToken);
        if (existingRelease)
            return;

        var wallet = await _context.Wallets.FirstAsync(w => w.CustomerId == booking.UserId, cancellationToken);
        var amount = payment.Amount;

        wallet.Balance += amount;
        wallet.ReservedBalance -= amount;
        if (wallet.ReservedBalance < 0)
            wallet.ReservedBalance = 0;
        wallet.UpdatedAt = DateTime.UtcNow;

        _context.WalletTransactions.Add(new WalletTransaction
        {
            WalletId = wallet.Id,
            CustomerId = booking.UserId,
            BookingId = booking.Id,
            Amount = amount,
            Type = WalletTransactionTypes.WalletRelease,
            Direction = WalletTransactionDirections.Credit,
            Status = WalletTransactionStatuses.Completed,
            PaymentMethod = WalletPaymentMethods.Wallet,
            Notes = "Booking wallet reservation released",
            CreatedAt = DateTime.UtcNow,
            CompletedAt = DateTime.UtcNow
        });

        payment.PaymentStatus = PaymentStatuses.Released;
        booking.WalletAmountReserved = false;

        await _notificationService.NotifyWalletReservationReleasedAsync(booking.Id, cancellationToken);
    }

    private async Task RefundCapturedAmountCoreAsync(Booking booking, CancellationToken cancellationToken)
    {
        if (!booking.WalletAmountCaptured)
            return;

        var payment = await GetWalletPaymentAsync(booking.Id, cancellationToken);
        if (payment == null || payment.WalletRefundStatus == WalletRefundStatuses.Refunded)
            return;

        var existingRefund = await _context.WalletTransactions.AnyAsync(
            t => t.BookingId == booking.Id
                && t.Type == WalletTransactionTypes.WalletRefund
                && t.Status == WalletTransactionStatuses.Completed,
            cancellationToken);
        if (existingRefund)
        {
            payment.WalletRefundStatus = WalletRefundStatuses.Refunded;
            return;
        }

        var wallet = await _context.Wallets.FirstAsync(w => w.CustomerId == booking.UserId, cancellationToken);
        var amount = payment.Amount;

        wallet.Balance += amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        _context.WalletTransactions.Add(new WalletTransaction
        {
            WalletId = wallet.Id,
            CustomerId = booking.UserId,
            BookingId = booking.Id,
            Amount = amount,
            Type = WalletTransactionTypes.WalletRefund,
            Direction = WalletTransactionDirections.Credit,
            Status = WalletTransactionStatuses.Completed,
            PaymentMethod = WalletPaymentMethods.Wallet,
            Notes = "Booking wallet refund",
            CreatedAt = DateTime.UtcNow,
            CompletedAt = DateTime.UtcNow
        });

        payment.WalletRefundStatus = WalletRefundStatuses.Refunded;
        booking.WalletAmountCaptured = false;
        booking.WalletCapturedAt = null;
        booking.WalletAmountReserved = false;

        await _notificationService.NotifyWalletAmountRefundedAsync(booking.Id, cancellationToken);
    }

    private async Task<Payment?> GetWalletPaymentAsync(int bookingId, CancellationToken cancellationToken) =>
        await _context.Payments
            .FirstOrDefaultAsync(
                p => p.BookingId == bookingId && p.PaymentMethod == WalletPaymentMethods.Wallet,
                cancellationToken);

    private async Task<bool> IsWalletBookingAsync(int bookingId, CancellationToken cancellationToken) =>
        await _context.Payments.AnyAsync(
            p => p.BookingId == bookingId && p.PaymentMethod == WalletPaymentMethods.Wallet,
            cancellationToken);

    private async Task<T> ExecuteSerializableAsync<T>(
        Func<CancellationToken, Task<T>> work,
        CancellationToken cancellationToken)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            var ownsTransaction = _context.Database.CurrentTransaction is null;
            await using var transaction = ownsTransaction
                ? await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken)
                : null;

            var result = await work(cancellationToken);

            if (ownsTransaction && transaction is not null)
                await transaction.CommitAsync(cancellationToken);

            return result;
        });
    }
}

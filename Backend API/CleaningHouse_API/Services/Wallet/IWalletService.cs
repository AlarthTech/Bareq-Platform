using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Wallet;

namespace CleaningHouse_API.Services.Wallet;

public interface IWalletService
{
    Task<WalletSummaryDTO> GetWalletSummaryAsync(int customerId, CancellationToken cancellationToken = default);
    Task<PagedResult<WalletTransactionDTO>> GetTransactionsAsync(
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> CreateTopUpAsync(
        int customerId,
        CreateWalletTopUpDTO dto,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO?> GetTopUpAsync(int customerId, int topUpId, CancellationToken cancellationToken = default);

    Task<BankTransferAccountDTO?> GetActiveBankTransferAccountForCustomerAsync(CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> ConfirmBankCardTopUpAsync(
        int topUpId,
        ConfirmBankCardTopUpDTO dto,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> FailBankCardTopUpAsync(
        int topUpId,
        FailBankCardTopUpDTO? dto,
        CancellationToken cancellationToken = default);

    Task<PagedResult<WalletTopUpDTO>> GetBankTransferTopUpsForAdminAsync(
        string? status,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> GetBankTransferTopUpByIdForAdminAsync(int id, CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> ApproveBankTransferTopUpAsync(
        int topUpId,
        int adminUserId,
        ApproveBankTransferTopUpDTO dto,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> RejectBankTransferTopUpAsync(
        int topUpId,
        int adminUserId,
        RejectBankTransferTopUpDTO dto,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<BankTransferAccountDTO>> GetBankAccountsAsync(CancellationToken cancellationToken = default);
    Task<BankTransferAccountDTO> CreateBankAccountAsync(CreateBankTransferAccountDTO dto, CancellationToken cancellationToken = default);
    Task<BankTransferAccountDTO> UpdateBankAccountAsync(int id, UpdateBankTransferAccountDTO dto, CancellationToken cancellationToken = default);
    Task<BankTransferAccountDTO> ActivateBankAccountAsync(int id, CancellationToken cancellationToken = default);
    Task<BankTransferAccountDTO> DeactivateBankAccountAsync(int id, CancellationToken cancellationToken = default);

    Task<WalletTransactionDTO> CreditCustomerWalletAsync(
        int customerId,
        int adminUserId,
        AdminManualWalletCreditDTO dto,
        CancellationToken cancellationToken = default);

    Task<BulkWalletCreditResultDTO> BulkCreditWalletsAsync(
        int adminUserId,
        AdminBulkWalletCreditDTO dto,
        CancellationToken cancellationToken = default);

    Task<WalletPaymentSettingsDTO> GetPaymentSettingsAsync(CancellationToken cancellationToken = default);
    Task<WalletPaymentSettingsDTO> UpdatePaymentSettingsAsync(
        UpdateWalletPaymentSettingsDTO dto,
        int adminUserId,
        CancellationToken cancellationToken = default);

    Task<WalletBookingPaymentQuoteDTO> GetBookingPaymentQuoteAsync(
        int customerId,
        decimal bookingTotal,
        CancellationToken cancellationToken = default);

    Task<WalletBookingPaymentResultDTO> ProcessBookingWalletPaymentAsync(
        int customerId,
        int bookingId,
        decimal bookingTotal,
        CancellationToken cancellationToken = default);

    Task<BankCardTopUpStartResponseDTO> StartBankCardTopUpAsync(
        int customerId,
        decimal amount,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpDTO> CreateBankTransferTopUpAsync(
        int customerId,
        CreateWalletTopUpDTO dto,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpCallbackResponseDTO> ProcessWalletTopUpCallbackAsync(
        WalletTopUpCallbackRequestDTO dto,
        CancellationToken cancellationToken = default);

    Task<WalletTopUpCallbackResponseDTO> TestInstantBankCardTopUpAsync(
        int customerId,
        decimal amount,
        CancellationToken cancellationToken = default);

    Task ProcessBookingWalletRefundAsync(int bookingId, CancellationToken cancellationToken = default);

    Task<Models.Wallet.Wallet> GetOrCreateWalletEntityAsync(int customerId, CancellationToken cancellationToken = default);
}

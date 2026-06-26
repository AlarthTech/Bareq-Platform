using CleaningHouse_API.Models.Wallet;

namespace CleaningHouse_API.Services.Wallet;

public interface IWalletPaymentSettingsRepository
{
    Task<WalletPaymentSettings> GetOrCreateAsync(CancellationToken cancellationToken = default);
    Task<WalletPaymentSettings> UpdateAsync(
        bool isEnabled,
        decimal feePercentage,
        int adminUserId,
        CancellationToken cancellationToken = default);
}

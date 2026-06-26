using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Wallet;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Wallet;

public class WalletPaymentSettingsRepository : IWalletPaymentSettingsRepository
{
    private readonly ApplicationDbContext _context;

    public WalletPaymentSettingsRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<WalletPaymentSettings> GetOrCreateAsync(CancellationToken cancellationToken = default)
    {
        var settings = await _context.WalletPaymentSettings.FirstOrDefaultAsync(cancellationToken);
        if (settings != null)
            return settings;

        settings = new WalletPaymentSettings
        {
            IsWalletPaymentEnabled = false,
            WalletPaymentFeePercentage = 0,
            UpdatedAt = DateTime.UtcNow
        };
        _context.WalletPaymentSettings.Add(settings);
        await _context.SaveChangesAsync(cancellationToken);
        return settings;
    }

    public async Task<WalletPaymentSettings> UpdateAsync(
        bool isEnabled,
        decimal feePercentage,
        int adminUserId,
        CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateAsync(cancellationToken);
        settings.IsWalletPaymentEnabled = isEnabled;
        settings.WalletPaymentFeePercentage = feePercentage;
        settings.UpdatedByAdminId = adminUserId;
        settings.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync(cancellationToken);
        return settings;
    }
}

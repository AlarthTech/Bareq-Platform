using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Admin;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Commission;

public class CommissionSettingRepository : ICommissionSettingRepository
{
    private readonly ApplicationDbContext _context;

    public CommissionSettingRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<CommissionSetting?> GetActiveAsync(CancellationToken cancellationToken = default) =>
        await _context.CommissionSettings
            .Where(s => s.IsActive)
            .OrderByDescending(s => s.UpdatedAt)
            .ThenByDescending(s => s.Id)
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<CommissionSetting> UpsertActiveAsync(
        decimal fixedPlatformFeeAmount,
        int adminUserId,
        CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var active = await GetActiveAsync(cancellationToken);

        if (active != null)
        {
            var others = await _context.CommissionSettings
                .Where(s => s.IsActive && s.Id != active.Id)
                .ToListAsync(cancellationToken);
            foreach (var other in others)
                other.IsActive = false;

            active.FixedPlatformFeeAmount = fixedPlatformFeeAmount;
            active.IsActive = true;
            active.UpdatedAt = now;
            active.UpdatedByAdminId = adminUserId;
        }
        else
        {
            var stale = await _context.CommissionSettings.Where(s => s.IsActive).ToListAsync(cancellationToken);
            foreach (var s in stale)
                s.IsActive = false;

            active = new CommissionSetting
            {
                FixedPlatformFeeAmount = fixedPlatformFeeAmount,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now,
                UpdatedByAdminId = adminUserId
            };
            _context.CommissionSettings.Add(active);
        }

        await _context.SaveChangesAsync(cancellationToken);
        return active;
    }
}

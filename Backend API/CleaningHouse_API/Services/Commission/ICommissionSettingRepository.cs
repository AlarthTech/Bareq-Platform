using CleaningHouse_API.Models.Admin;

namespace CleaningHouse_API.Services.Commission;

public interface ICommissionSettingRepository
{
    Task<CommissionSetting?> GetActiveAsync(CancellationToken cancellationToken = default);
    Task<CommissionSetting> UpsertActiveAsync(decimal fixedPlatformFeeAmount, int adminUserId, CancellationToken cancellationToken = default);
}

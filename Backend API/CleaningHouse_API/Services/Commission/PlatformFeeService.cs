using CleaningHouse_API.DTOs.Admin;

namespace CleaningHouse_API.Services.Commission;

public class PlatformFeeService : IPlatformFeeService
{
    private readonly ICommissionSettingRepository _repository;

    public PlatformFeeService(ICommissionSettingRepository repository)
    {
        _repository = repository;
    }

    public async Task<PlatformFeeResponseDTO> GetCurrentPlatformFeeAsync(CancellationToken cancellationToken = default)
    {
        var amount = await GetActivePlatformFeeAmountAsync(cancellationToken);
        return new PlatformFeeResponseDTO { FixedPlatformFeeAmount = amount };
    }

    public async Task<UpdatePlatformFeeResponseDTO> UpdatePlatformFeeAsync(
        decimal amount,
        int adminUserId,
        CancellationToken cancellationToken = default)
    {
        if (amount < 0)
            throw new ArgumentOutOfRangeException(nameof(amount), "Platform fee cannot be negative.");

        var updated = await _repository.UpsertActiveAsync(amount, adminUserId, cancellationToken);
        return new UpdatePlatformFeeResponseDTO
        {
            Success = true,
            FixedPlatformFeeAmount = updated.FixedPlatformFeeAmount
        };
    }

    public async Task<decimal> GetActivePlatformFeeAmountAsync(CancellationToken cancellationToken = default)
    {
        var active = await _repository.GetActiveAsync(cancellationToken);
        return active?.FixedPlatformFeeAmount ?? 0m;
    }
}

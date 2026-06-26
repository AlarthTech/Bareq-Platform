using CleaningHouse_API.DTOs.Admin;

namespace CleaningHouse_API.Services.Commission;

public interface IPlatformFeeService
{
    Task<PlatformFeeResponseDTO> GetCurrentPlatformFeeAsync(CancellationToken cancellationToken = default);
    Task<UpdatePlatformFeeResponseDTO> UpdatePlatformFeeAsync(decimal amount, int adminUserId, CancellationToken cancellationToken = default);
    Task<decimal> GetActivePlatformFeeAmountAsync(CancellationToken cancellationToken = default);
}

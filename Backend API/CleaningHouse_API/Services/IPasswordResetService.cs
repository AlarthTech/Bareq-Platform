using CleaningHouse_API.DTOs.Common;

namespace CleaningHouse_API.Services;

public interface IPasswordResetService
{
    Task<ForgotPasswordResponseDto> RequestOtpAsync(
        ForgotPasswordRequestDto request,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken = default);

    Task<VerifyResetCodeResponseDto?> VerifyCodeAsync(
        VerifyResetCodeRequestDto request,
        CancellationToken cancellationToken = default);

    Task<MessageResponseDto?> ResetPasswordAsync(
        ResetPasswordRequestDto request,
        CancellationToken cancellationToken = default);
}

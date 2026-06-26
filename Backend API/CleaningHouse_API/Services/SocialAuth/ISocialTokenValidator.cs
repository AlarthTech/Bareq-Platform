using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Services.SocialAuth;

public sealed class SocialAuthUserInfo
{
    public ExternalAuthProvider Provider { get; init; }
    public string ProviderUserId { get; init; } = string.Empty;
    public string? Email { get; init; }
    public string? FullName { get; init; }
}

public interface ISocialTokenValidator
{
    ExternalAuthProvider Provider { get; }
    Task<SocialAuthUserInfo?> ValidateAsync(string token, CancellationToken cancellationToken = default);
}

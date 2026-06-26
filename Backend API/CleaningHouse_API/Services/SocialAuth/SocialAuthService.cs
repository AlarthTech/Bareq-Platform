using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Services.SocialAuth;

public interface ISocialAuthService
{
    Task<SocialAuthUserInfo?> ValidateTokenAsync(
        ExternalAuthProvider provider,
        string? idToken,
        string? accessToken,
        CancellationToken cancellationToken = default);
}

public class SocialAuthService : ISocialAuthService
{
    private readonly IReadOnlyDictionary<ExternalAuthProvider, ISocialTokenValidator> _validators;

    public SocialAuthService(IEnumerable<ISocialTokenValidator> validators)
    {
        _validators = validators.ToDictionary(v => v.Provider);
    }

    public Task<SocialAuthUserInfo?> ValidateTokenAsync(
        ExternalAuthProvider provider,
        string? idToken,
        string? accessToken,
        CancellationToken cancellationToken = default)
    {
        if (!_validators.TryGetValue(provider, out var validator))
            return Task.FromResult<SocialAuthUserInfo?>(null);

        var token = provider switch
        {
            ExternalAuthProvider.Facebook => accessToken,
            _ => idToken
        };

        if (string.IsNullOrWhiteSpace(token))
            return Task.FromResult<SocialAuthUserInfo?>(null);

        return validator.ValidateAsync(token, cancellationToken);
    }
}

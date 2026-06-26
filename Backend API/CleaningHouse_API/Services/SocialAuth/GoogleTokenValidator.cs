using CleaningHouse_API.Configuration;
using CleaningHouse_API.Models.Common;
using Google.Apis.Auth;
using Microsoft.Extensions.Options;

namespace CleaningHouse_API.Services.SocialAuth;

public class GoogleTokenValidator : ISocialTokenValidator
{
    private readonly GoogleSocialAuthSettings _settings;

    public GoogleTokenValidator(IOptions<SocialAuthSettings> options)
    {
        _settings = options.Value.Google;
    }

    public ExternalAuthProvider Provider => ExternalAuthProvider.Google;

    public async Task<SocialAuthUserInfo?> ValidateAsync(string token, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token) || _settings.ClientIds.Count == 0)
            return null;

        try
        {
            var validationSettings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = _settings.ClientIds
            };

            var payload = await GoogleJsonWebSignature.ValidateAsync(token, validationSettings);

            return new SocialAuthUserInfo
            {
                Provider = ExternalAuthProvider.Google,
                ProviderUserId = payload.Subject,
                Email = payload.Email,
                FullName = payload.Name
            };
        }
        catch
        {
            return null;
        }
    }
}

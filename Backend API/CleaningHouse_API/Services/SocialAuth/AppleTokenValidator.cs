using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using CleaningHouse_API.Configuration;
using CleaningHouse_API.Models.Common;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace CleaningHouse_API.Services.SocialAuth;

public class AppleTokenValidator : ISocialTokenValidator
{
    private const string AppleIssuer = "https://appleid.apple.com";
    private const string AppleKeysUrl = "https://appleid.apple.com/auth/keys";

    private readonly AppleSocialAuthSettings _settings;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly SemaphoreSlim _keysLock = new(1, 1);
    private IList<SecurityKey>? _cachedKeys;
    private DateTime _keysFetchedAt = DateTime.MinValue;
    private static readonly TimeSpan KeysCacheDuration = TimeSpan.FromHours(12);

    public AppleTokenValidator(IOptions<SocialAuthSettings> options, IHttpClientFactory httpClientFactory)
    {
        _settings = options.Value.Apple;
        _httpClientFactory = httpClientFactory;
    }

    public ExternalAuthProvider Provider => ExternalAuthProvider.Apple;

    public async Task<SocialAuthUserInfo?> ValidateAsync(string token, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token) || _settings.ClientIds.Count == 0)
            return null;

        try
        {
            var keys = await GetSigningKeysAsync(cancellationToken);
            var handler = new JwtSecurityTokenHandler();
            var parameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = AppleIssuer,
                ValidateAudience = true,
                ValidAudiences = _settings.ClientIds,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(2),
                IssuerSigningKeys = keys
            };

            var principal = handler.ValidateToken(token, parameters, out _);
            var sub = principal.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? principal.FindFirstValue("sub");
            if (string.IsNullOrWhiteSpace(sub))
                return null;

            var email = principal.FindFirstValue(ClaimTypes.Email)
                ?? principal.FindFirstValue("email");

            return new SocialAuthUserInfo
            {
                Provider = ExternalAuthProvider.Apple,
                ProviderUserId = sub,
                Email = email
            };
        }
        catch
        {
            return null;
        }
    }

    private async Task<IList<SecurityKey>> GetSigningKeysAsync(CancellationToken cancellationToken)
    {
        if (_cachedKeys != null && DateTime.UtcNow - _keysFetchedAt < KeysCacheDuration)
            return _cachedKeys;

        await _keysLock.WaitAsync(cancellationToken);
        try
        {
            if (_cachedKeys != null && DateTime.UtcNow - _keysFetchedAt < KeysCacheDuration)
                return _cachedKeys;

            var client = _httpClientFactory.CreateClient(nameof(AppleTokenValidator));
            var json = await client.GetStringAsync(AppleKeysUrl, cancellationToken);
            var jwks = new JsonWebKeySet(json);
            _cachedKeys = jwks.GetSigningKeys();
            _keysFetchedAt = DateTime.UtcNow;
            return _cachedKeys;
        }
        finally
        {
            _keysLock.Release();
        }
    }
}

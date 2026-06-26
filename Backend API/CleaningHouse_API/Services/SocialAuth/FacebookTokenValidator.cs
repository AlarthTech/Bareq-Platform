using System.Net.Http.Json;
using System.Text.Json.Serialization;
using CleaningHouse_API.Configuration;
using CleaningHouse_API.Models.Common;
using Microsoft.Extensions.Options;

namespace CleaningHouse_API.Services.SocialAuth;

public class FacebookTokenValidator : ISocialTokenValidator
{
    private readonly FacebookSocialAuthSettings _settings;
    private readonly IHttpClientFactory _httpClientFactory;

    public FacebookTokenValidator(IOptions<SocialAuthSettings> options, IHttpClientFactory httpClientFactory)
    {
        _settings = options.Value.Facebook;
        _httpClientFactory = httpClientFactory;
    }

    public ExternalAuthProvider Provider => ExternalAuthProvider.Facebook;

    public async Task<SocialAuthUserInfo?> ValidateAsync(string token, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token) || !_settings.IsConfigured)
            return null;

        try
        {
            var client = _httpClientFactory.CreateClient(nameof(FacebookTokenValidator));
            var appAccessToken = $"{_settings.AppId}|{_settings.AppSecret}";

            var debugUrl =
                $"https://graph.facebook.com/debug_token?input_token={Uri.EscapeDataString(token)}&access_token={Uri.EscapeDataString(appAccessToken)}";
            var debugResponse = await client.GetFromJsonAsync<FacebookDebugTokenResponse>(debugUrl, cancellationToken);
            if (debugResponse?.Data?.IsValid != true || string.IsNullOrWhiteSpace(debugResponse.Data.UserId))
                return null;

            if (!string.Equals(debugResponse.Data.AppId, _settings.AppId, StringComparison.Ordinal))
                return null;

            var meUrl =
                $"https://graph.facebook.com/me?fields=id,name,email&access_token={Uri.EscapeDataString(token)}";
            var profile = await client.GetFromJsonAsync<FacebookProfileResponse>(meUrl, cancellationToken);
            if (profile == null || string.IsNullOrWhiteSpace(profile.Id))
                return null;

            return new SocialAuthUserInfo
            {
                Provider = ExternalAuthProvider.Facebook,
                ProviderUserId = profile.Id,
                Email = profile.Email,
                FullName = profile.Name
            };
        }
        catch
        {
            return null;
        }
    }

    private sealed class FacebookDebugTokenResponse
    {
        [JsonPropertyName("data")]
        public FacebookDebugTokenData? Data { get; set; }
    }

    private sealed class FacebookDebugTokenData
    {
        [JsonPropertyName("app_id")]
        public string? AppId { get; set; }

        [JsonPropertyName("user_id")]
        public string? UserId { get; set; }

        [JsonPropertyName("is_valid")]
        public bool IsValid { get; set; }
    }

    private sealed class FacebookProfileResponse
    {
        [JsonPropertyName("id")]
        public string? Id { get; set; }

        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("email")]
        public string? Email { get; set; }
    }
}

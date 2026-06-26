namespace CleaningHouse_API.Configuration;

public class SocialAuthSettings
{
    public const string SectionName = "SocialAuth";

    public GoogleSocialAuthSettings Google { get; set; } = new();
    public AppleSocialAuthSettings Apple { get; set; } = new();
    public FacebookSocialAuthSettings Facebook { get; set; } = new();
}

public class GoogleSocialAuthSettings
{
    public List<string> ClientIds { get; set; } = new();
}

public class AppleSocialAuthSettings
{
    public List<string> ClientIds { get; set; } = new();
}

public class FacebookSocialAuthSettings
{
    public string AppId { get; set; } = string.Empty;
    public string AppSecret { get; set; } = string.Empty;

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(AppId) && !string.IsNullOrWhiteSpace(AppSecret);
}

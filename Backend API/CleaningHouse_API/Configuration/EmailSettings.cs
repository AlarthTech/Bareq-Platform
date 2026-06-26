using MailKit.Security;

namespace CleaningHouse_API.Configuration;

public class EmailSettings
{
    public const string SectionName = "EmailSettings";

    public string FromEmail { get; set; } = string.Empty;
    public string FromName { get; set; } = "Bareq";
    public string SmtpHost { get; set; } = string.Empty;
    public int SmtpPort { get; set; } = 465;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// SslOnConnect | StartTls | StartTlsWhenAvailable | None
    /// Standard ports 465/587/25 override this when not using a custom port.
    /// </summary>
    public string SecureSocketMode { get; set; } = "SslOnConnect";

    /// <summary>Legacy; ignored when SecureSocketMode is set. Prefer SecureSocketMode.</summary>
    public bool UseSsl { get; set; } = true;

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(SmtpHost)
        && !string.IsNullOrWhiteSpace(FromEmail)
        && !string.IsNullOrWhiteSpace(Username)
        && !string.IsNullOrWhiteSpace(Password);

    public SecureSocketOptions ResolveSecureSocketOptions() =>
        SmtpSocketModeResolver.Resolve(SmtpPort, SecureSocketMode, UseSsl);
}

public static class SmtpSocketModeResolver
{
    public static SecureSocketOptions Resolve(int port, string? configuredMode, bool legacyUseSsl)
    {
        return port switch
        {
            465 => SecureSocketOptions.SslOnConnect,
            587 => SecureSocketOptions.StartTls,
            25 => SecureSocketOptions.StartTlsWhenAvailable,
            _ => ParseConfiguredMode(configuredMode, legacyUseSsl)
        };
    }

    public static string DescribeMode(SecureSocketOptions options) => options switch
    {
        SecureSocketOptions.SslOnConnect => "SslOnConnect",
        SecureSocketOptions.StartTls => "StartTls",
        SecureSocketOptions.StartTlsWhenAvailable => "StartTlsWhenAvailable",
        SecureSocketOptions.None => "None",
        SecureSocketOptions.Auto => "Auto",
        _ => options.ToString()
    };

    private static SecureSocketOptions ParseConfiguredMode(string? configuredMode, bool legacyUseSsl)
    {
        if (string.IsNullOrWhiteSpace(configuredMode))
            return legacyUseSsl ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTlsWhenAvailable;

        return configuredMode.Trim().ToLowerInvariant() switch
        {
            "sslonconnect" or "ssl-on-connect" => SecureSocketOptions.SslOnConnect,
            "starttls" or "start-tls" => SecureSocketOptions.StartTls,
            "starttlswhenavailable" or "start-tls-when-available" => SecureSocketOptions.StartTlsWhenAvailable,
            "none" => SecureSocketOptions.None,
            "auto" => SecureSocketOptions.Auto,
            _ => Enum.TryParse<SecureSocketOptions>(configuredMode, ignoreCase: true, out var parsed)
                ? parsed
                : SecureSocketOptions.SslOnConnect
        };
    }
}

namespace CleaningHouse_API.Services;

public interface IEmailSender
{
    Task SendPasswordResetOtpAsync(string toEmail, string otp, CancellationToken cancellationToken = default);

    Task SendCompanyPasswordResetOtpAsync(string toEmail, string otp, CancellationToken cancellationToken = default);

    Task SendWelcomeEmailAsync(string toEmail, string userName, CancellationToken cancellationToken = default);

    Task SendPasswordChangedEmailAsync(string toEmail, string userName, CancellationToken cancellationToken = default);

    Task SendAutoReplyEmailAsync(string toEmail, string? senderName = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Admin preview: password-reset-otp | welcome | password-changed | auto-reply
    /// </summary>
    Task SendTestEmailAsync(string toEmail, string? template = null, CancellationToken cancellationToken = default);
}

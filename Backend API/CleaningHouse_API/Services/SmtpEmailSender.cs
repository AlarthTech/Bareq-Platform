using CleaningHouse_API.Configuration;
using CleaningHouse_API.Helpers;
using CleaningHouse_API.Services.Email;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace CleaningHouse_API.Services;

public class SmtpEmailSender : IEmailSender
{
    private readonly EmailSettings _settings;
    private readonly ILogger<SmtpEmailSender> _logger;

    public SmtpEmailSender(IOptions<EmailSettings> settings, ILogger<SmtpEmailSender> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public Task SendPasswordResetOtpAsync(string toEmail, string otp, CancellationToken cancellationToken = default) =>
        SendMultipartAsync(
            toEmail,
            EmailTemplateService.PasswordResetSubject,
            EmailTemplateService.BuildPasswordResetOtpText(otp),
            EmailTemplateService.BuildPasswordResetOtpHtml(otp),
            "password-reset-otp",
            cancellationToken);

    public Task SendCompanyPasswordResetOtpAsync(string toEmail, string otp, CancellationToken cancellationToken = default) =>
        SendPasswordResetOtpAsync(toEmail, otp, cancellationToken);

    public Task SendWelcomeEmailAsync(string toEmail, string userName, CancellationToken cancellationToken = default) =>
        SendMultipartAsync(
            toEmail,
            EmailTemplateService.WelcomeSubject,
            EmailTemplateService.BuildWelcomeEmailText(userName),
            EmailTemplateService.BuildWelcomeEmailHtml(userName),
            "welcome",
            cancellationToken);

    public Task SendPasswordChangedEmailAsync(string toEmail, string userName, CancellationToken cancellationToken = default) =>
        SendMultipartAsync(
            toEmail,
            EmailTemplateService.PasswordChangedSubject,
            EmailTemplateService.BuildPasswordChangedText(userName),
            EmailTemplateService.BuildPasswordChangedHtml(userName),
            "password-changed",
            cancellationToken);

    public Task SendAutoReplyEmailAsync(string toEmail, string? senderName = null, CancellationToken cancellationToken = default) =>
        SendMultipartAsync(
            toEmail,
            EmailTemplateService.AutoReplySubject,
            EmailTemplateService.BuildAutoReplyEmailText(senderName),
            EmailTemplateService.BuildAutoReplyEmailHtml(senderName),
            "auto-reply",
            cancellationToken);

    public Task SendTestEmailAsync(string toEmail, string? template = null, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(template))
        {
            return SendMultipartAsync(
                toEmail,
                "Bareq SMTP Test",
                "This is a test email from Bareq backend.",
                null,
                "smtp-test",
                cancellationToken);
        }

        return template.Trim().ToLowerInvariant() switch
        {
            "password-reset-otp" => SendPasswordResetOtpAsync(
                toEmail, EmailTemplateService.PreviewOtpCode, cancellationToken),
            "welcome" => SendWelcomeEmailAsync(
                toEmail, EmailTemplateService.PreviewUserName, cancellationToken),
            "password-changed" => SendPasswordChangedEmailAsync(
                toEmail, EmailTemplateService.PreviewUserName, cancellationToken),
            "auto-reply" => SendAutoReplyEmailAsync(
                toEmail, EmailTemplateService.PreviewUserName, cancellationToken),
            _ => SendMultipartAsync(
                toEmail,
                "Bareq SMTP Test",
                $"Unknown template '{template}'. Use: password-reset-otp, welcome, password-changed, auto-reply.",
                null,
                "smtp-test",
                cancellationToken)
        };
    }

    private async Task SendMultipartAsync(
        string toEmail,
        string subject,
        string plainText,
        string? htmlBody,
        string purpose,
        CancellationToken cancellationToken)
    {
        if (!_settings.IsConfigured)
        {
            _logger.LogWarning(
                "SMTP not configured; skipping {Purpose} email. Host={Host} Port={Port}",
                purpose,
                string.IsNullOrWhiteSpace(_settings.SmtpHost) ? "(empty)" : _settings.SmtpHost,
                _settings.SmtpPort);
            throw new InvalidOperationException("SMTP is not configured.");
        }

        var socketMode = _settings.ResolveSecureSocketOptions();
        var modeName = SmtpSocketModeResolver.DescribeMode(socketMode);
        var maskedTo = EmailMasking.Mask(toEmail);

        _logger.LogInformation(
            "Sending {Purpose} email via SMTP {Host}:{Port} Mode={Mode} From={FromEmail} To={MaskedEmail} Subject={Subject} Format={Format}",
            purpose,
            _settings.SmtpHost,
            _settings.SmtpPort,
            modeName,
            _settings.FromEmail,
            maskedTo,
            subject,
            htmlBody == null ? "text" : "html+text");

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_settings.FromName, _settings.FromEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = subject;

        var builder = new BodyBuilder { TextBody = plainText };
        if (!string.IsNullOrEmpty(htmlBody))
            builder.HtmlBody = htmlBody;
        message.Body = builder.ToMessageBody();

        try
        {
            using var client = new SmtpClient();
            await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort, socketMode, cancellationToken);
            await client.AuthenticateAsync(_settings.Username, _settings.Password, cancellationToken);
            await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);

            _logger.LogInformation(
                "SMTP send succeeded {Purpose} via {Host}:{Port} Mode={Mode} From={FromEmail} To={MaskedEmail}",
                purpose,
                _settings.SmtpHost,
                _settings.SmtpPort,
                modeName,
                _settings.FromEmail,
                maskedTo);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "SMTP send failed {Purpose} via {Host}:{Port} Mode={Mode} From={FromEmail} To={MaskedEmail}. Error={ErrorMessage}",
                purpose,
                _settings.SmtpHost,
                _settings.SmtpPort,
                modeName,
                _settings.FromEmail,
                maskedTo,
                ex.Message);

            throw;
        }
    }
}

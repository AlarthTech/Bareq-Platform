using CleaningHouse_API.Configuration;
using CleaningHouse_API.Helpers;
using Microsoft.Extensions.Options;

namespace CleaningHouse_API.Services.Email;

public class TransactionalEmailQueue : ITransactionalEmailQueue
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<TransactionalEmailQueue> _logger;

    public TransactionalEmailQueue(
        IServiceScopeFactory scopeFactory,
        IOptions<EmailSettings> emailSettings,
        ILogger<TransactionalEmailQueue> logger)
    {
        _scopeFactory = scopeFactory;
        _emailSettings = emailSettings.Value;
        _logger = logger;
    }

    public void Enqueue(Func<IEmailSender, Task> sendAction, string purpose, string toEmail)
    {
        if (!_emailSettings.IsConfigured)
        {
            _logger.LogWarning(
                "Email not configured; skipping {Purpose} for {MaskedEmail}",
                purpose,
                EmailMasking.Mask(toEmail));
            return;
        }

        var masked = EmailMasking.Mask(toEmail);
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var sender = scope.ServiceProvider.GetRequiredService<IEmailSender>();
                await sendAction(sender);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Background email failed {Purpose} to {MaskedEmail}. Host={Host} Port={Port}. Error={ErrorMessage}",
                    purpose,
                    masked,
                    _emailSettings.SmtpHost,
                    _emailSettings.SmtpPort,
                    ex.Message);
            }
        });
    }
}

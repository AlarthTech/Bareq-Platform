namespace CleaningHouse_API.Services;

public sealed class HealthCertificateExpiryHostedService : BackgroundService
{
    private static readonly TimeSpan Period = TimeSpan.FromHours(24);
    private readonly IServiceProvider _services;
    private readonly ILogger<HealthCertificateExpiryHostedService> _logger;

    public HealthCertificateExpiryHostedService(
        IServiceProvider services,
        ILogger<HealthCertificateExpiryHostedService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Health certificate expiry notification job started.");

        await RunCheckAsync(stoppingToken);

        using var timer = new PeriodicTimer(Period);
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await RunCheckAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health certificate expiry job failed; will retry on next interval.");
            }
        }

        _logger.LogInformation("Health certificate expiry notification job stopped.");
    }

    private async Task RunCheckAsync(CancellationToken cancellationToken)
    {
        using var scope = _services.CreateScope();
        var notificationService = scope.ServiceProvider.GetRequiredService<Notifications.INotificationService>();
        await notificationService.CheckHealthCertificateExpirationsAsync(cancellationToken);
        _logger.LogInformation("Health certificate expiry check completed.");
    }
}

using System.Data;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Services.Notifications;
using CleaningHouse_API.Services.Wallet;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services;

public class BookingAutoCompleteHostedService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<BookingAutoCompleteHostedService> _logger;
    private static readonly TimeSpan Period = TimeSpan.FromMinutes(5);

    public BookingAutoCompleteHostedService(
        IServiceProvider services,
        ILogger<BookingAutoCompleteHostedService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Booking auto-complete background service started.");

        using var timer = new PeriodicTimer(Period);
        do
        {
            try
            {
                using var scope = _services.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<Data.ApplicationDbContext>();
                var notifications = scope.ServiceProvider.GetRequiredService<INotificationService>();
                var bookingWallet = scope.ServiceProvider.GetRequiredService<IBookingWalletService>();

                var completed = await BookingAutoCompletion.CompleteDueBookingsAsync(db, stoppingToken);
                foreach (var item in completed)
                {
                    var booking = await db.Bookings.FirstOrDefaultAsync(
                        b => b.Id == item.BookingId,
                        stoppingToken);
                    if (booking != null)
                    {
                        await using var transaction = await db.Database.BeginTransactionAsync(
                            IsolationLevel.Serializable,
                            stoppingToken);
                        await bookingWallet.ApplyBookingStatusWalletEffectsAsync(
                            booking,
                            item.PreviousStatus,
                            BookingStatuses.Completed,
                            stoppingToken);
                        await transaction.CommitAsync(stoppingToken);
                    }

                    await notifications.NotifyBookingStatusChangedAsync(
                        item.BookingId,
                        item.PreviousStatus,
                        BookingStatuses.Completed,
                        stoppingToken);
                }

                if (completed.Count > 0)
                    _logger.LogInformation("Auto-completed {Count} booking(s).", completed.Count);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Booking auto-complete job failed; will retry on next interval.");
            }
        } while (await timer.WaitForNextTickAsync(stoppingToken));

        _logger.LogInformation("Booking auto-complete background service stopped.");
    }
}

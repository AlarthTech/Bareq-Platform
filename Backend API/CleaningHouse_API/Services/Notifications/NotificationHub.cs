using System.Security.Claims;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Models.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace CleaningHouse_API.Services.Notifications;

public interface INotificationRealtimeSender
{
    Task SendToUserAsync(int userId, NotificationDTO notification, int unreadCount, CancellationToken cancellationToken = default);
}

public class SignalRNotificationSender : INotificationRealtimeSender
{
    private readonly IHubContext<NotificationHub> _hubContext;

    public SignalRNotificationSender(IHubContext<NotificationHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task SendToUserAsync(
        int userId,
        NotificationDTO notification,
        int unreadCount,
        CancellationToken cancellationToken = default)
    {
        var client = _hubContext.Clients.User(userId.ToString());

        if (IsBookingNotification(notification.NotificationType))
        {
            await client.SendAsync("BookingStatusChanged", notification, cancellationToken);
        }

        await client.SendAsync("ReceiveNotification", notification, unreadCount, cancellationToken);
    }

    private static bool IsBookingNotification(NotificationType type) =>
        type is NotificationType.BookingCreated
            or NotificationType.BookingAssigned
            or NotificationType.BookingConfirmed
            or NotificationType.BookingInProgress
            or NotificationType.BookingCompleted
            or NotificationType.BookingCancelled
            or NotificationType.BookingRejected
            or NotificationType.WorkerArrivalConfirmed
            or NotificationType.WalletAmountCaptured
            or NotificationType.WalletReservationReleased
            or NotificationType.WalletAmountRefunded;
}

/// <summary>
/// Maps JWT <see cref="ClaimTypes.NameIdentifier"/> to SignalR user ids for Clients.User().
/// </summary>
public sealed class NotificationUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection) =>
        connection.User?.FindFirstValue(ClaimTypes.NameIdentifier);
}

[Authorize]
public class NotificationHub : Hub
{
}

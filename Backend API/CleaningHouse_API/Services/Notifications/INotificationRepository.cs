using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Services.Notifications;

public interface INotificationRepository
{
    Task<Notification> AddAsync(Notification notification, CancellationToken cancellationToken = default);
    Task<Notification?> GetByIdForUserAsync(int id, int userId, CancellationToken cancellationToken = default);
    Task<PagedResult<Notification>> GetUserNotificationsAsync(
        int userId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);
    Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(
        int userId,
        NotificationType type,
        int? relatedEntityId,
        CancellationToken cancellationToken = default);
    Task MarkAsReadAsync(Notification notification, CancellationToken cancellationToken = default);
    Task<int> MarkAllAsReadAsync(int userId, CancellationToken cancellationToken = default);
    Task SoftDeleteAsync(Notification notification, CancellationToken cancellationToken = default);
    Task SoftDeleteHealthExpiryForWorkerAsync(int workerId, CancellationToken cancellationToken = default);
}

using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Common;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Notifications;

public class NotificationRepository : INotificationRepository
{
    private readonly ApplicationDbContext _context;

    public NotificationRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Notification> AddAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync(cancellationToken);
        return notification;
    }

    public Task<Notification?> GetByIdForUserAsync(int id, int userId, CancellationToken cancellationToken = default) =>
        _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId && !n.IsDeleted, cancellationToken);

    public async Task<PagedResult<Notification>> GetUserNotificationsAsync(
        int userId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var query = _context.Notifications.AsNoTracking()
            .Where(n => n.UserId == userId && !n.IsDeleted)
            .OrderByDescending(n => n.CreatedAt);

        return await query.ToPagedResultAsync(pagination, cancellationToken);
    }

    public Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default) =>
        _context.Notifications.CountAsync(
            n => n.UserId == userId && !n.IsRead && !n.IsDeleted,
            cancellationToken);

    public Task<bool> ExistsAsync(
        int userId,
        NotificationType type,
        int? relatedEntityId,
        CancellationToken cancellationToken = default) =>
        _context.Notifications.AnyAsync(
            n => n.UserId == userId
                && n.NotificationType == type
                && n.RelatedEntityId == relatedEntityId
                && !n.IsDeleted,
            cancellationToken);

    public async Task MarkAsReadAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        notification.IsRead = true;
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> MarkAllAsReadAsync(int userId, CancellationToken cancellationToken = default)
    {
        var unread = await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead && !n.IsDeleted)
            .ToListAsync(cancellationToken);

        foreach (var n in unread)
            n.IsRead = true;

        await _context.SaveChangesAsync(cancellationToken);
        return unread.Count;
    }

    public async Task SoftDeleteAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        notification.IsDeleted = true;
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task SoftDeleteHealthExpiryForWorkerAsync(int workerId, CancellationToken cancellationToken = default)
    {
        var items = await _context.Notifications
            .Where(n => n.NotificationType == NotificationType.WorkerHealthCertificateExpired
                && n.RelatedEntityId == workerId
                && !n.IsDeleted)
            .ToListAsync(cancellationToken);

        foreach (var n in items)
            n.IsDeleted = true;

        if (items.Count > 0)
            await _context.SaveChangesAsync(cancellationToken);
    }
}

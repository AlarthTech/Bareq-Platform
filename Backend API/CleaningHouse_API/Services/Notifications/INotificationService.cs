using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Services.Notifications;

public interface INotificationService
{
    Task<NotificationDTO> CreateNotificationAsync(
        int userId,
        NotificationPayload payload,
        bool skipIfDuplicate = false,
        CancellationToken cancellationToken = default);

    Task CreateForAllAdminsAsync(
        NotificationPayload payload,
        bool skipIfDuplicate = false,
        CancellationToken cancellationToken = default);

    Task NotifyNewCompanyPendingApprovalAsync(int companyId, CancellationToken cancellationToken = default);
    Task NotifyNewWorkerPendingApprovalAsync(int workerId, CancellationToken cancellationToken = default);
    Task NotifyCustomerReportAsync(int reportId, CancellationToken cancellationToken = default);
    Task NotifyBookingReportCreatedAsync(int reportId, CancellationToken cancellationToken = default);
    Task NotifyBookingReportStatusUpdatedAsync(int reportId, CancellationToken cancellationToken = default);
    Task NotifyBookingCreatedAsync(int bookingId, CancellationToken cancellationToken = default);
    Task NotifyBookingStatusChangedAsync(int bookingId, int previousStatus, int newStatus, CancellationToken cancellationToken = default);
    Task NotifyWorkerArrivalConfirmedAsync(int bookingId, CancellationToken cancellationToken = default);
    Task NotifyWalletAmountCapturedAsync(int bookingId, CancellationToken cancellationToken = default);
    Task NotifyWalletReservationReleasedAsync(int bookingId, CancellationToken cancellationToken = default);
    Task NotifyWalletAmountRefundedAsync(int bookingId, CancellationToken cancellationToken = default);
    Task CheckHealthCertificateExpirationsAsync(CancellationToken cancellationToken = default);
    Task ClearHealthExpiryNotificationsForWorkerAsync(int workerId, CancellationToken cancellationToken = default);

    Task<PagedResult<NotificationDTO>> GetUserNotificationsAsync(
        int userId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<NotificationDTO?> GetNotificationByIdAsync(int id, int userId, CancellationToken cancellationToken = default);
    Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default);
    Task<bool> MarkAsReadAsync(int id, int userId, CancellationToken cancellationToken = default);
    Task<int> MarkAllAsReadAsync(int userId, CancellationToken cancellationToken = default);
    Task<bool> SoftDeleteAsync(int id, int userId, CancellationToken cancellationToken = default);
}

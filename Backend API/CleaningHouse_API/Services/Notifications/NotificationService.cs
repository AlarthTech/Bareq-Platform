using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Customers;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Notifications;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly INotificationRepository _repository;
    private readonly INotificationRealtimeSender _realtimeSender;
    private readonly IMapper _mapper;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        ApplicationDbContext context,
        INotificationRepository repository,
        INotificationRealtimeSender realtimeSender,
        IMapper mapper,
        ILogger<NotificationService> logger)
    {
        _context = context;
        _repository = repository;
        _realtimeSender = realtimeSender;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<NotificationDTO> CreateNotificationAsync(
        int userId,
        NotificationPayload payload,
        bool skipIfDuplicate = false,
        CancellationToken cancellationToken = default)
    {
        if (skipIfDuplicate && await _repository.ExistsAsync(
                userId, payload.NotificationType, payload.RelatedEntityId, cancellationToken))
        {
            var existing = await _context.Notifications.AsNoTracking()
                .Where(n => n.UserId == userId
                    && n.NotificationType == payload.NotificationType
                    && n.RelatedEntityId == payload.RelatedEntityId
                    && !n.IsDeleted)
                .OrderByDescending(n => n.CreatedAt)
                .FirstAsync(cancellationToken);
            return MapToDto(existing);
        }

        var entity = new Notification
        {
            UserId = userId,
            Title = payload.Title,
            TitleAr = payload.TitleAr,
            Message = payload.Message,
            MessageAr = payload.MessageAr,
            NotificationType = payload.NotificationType,
            RelatedEntityId = payload.RelatedEntityId,
            IsRead = false,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow
        };

        await _repository.AddAsync(entity, cancellationToken);
        var dto = MapToDto(entity);

        try
        {
            var unread = await _repository.GetUnreadCountAsync(userId, cancellationToken);
            await _realtimeSender.SendToUserAsync(userId, dto, unread, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Real-time notification push failed for user {UserId}", userId);
        }

        return dto;
    }

    public async Task CreateForAllAdminsAsync(
        NotificationPayload payload,
        bool skipIfDuplicate = false,
        CancellationToken cancellationToken = default)
    {
        var adminIds = await GetActiveAdminUserIdsAsync(cancellationToken);
        foreach (var adminId in adminIds)
        {
            await CreateNotificationAsync(adminId, payload, skipIfDuplicate, cancellationToken);
        }
    }

    public async Task NotifyNewCompanyPendingApprovalAsync(int companyId, CancellationToken cancellationToken = default)
    {
        var company = await _context.Companies.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == companyId, cancellationToken);
        if (company == null)
            return;

        var payload = NotificationTemplates.NewCompanyPendingApproval(companyId, company.Name);
        await CreateForAllAdminsAsync(payload, skipIfDuplicate: true, cancellationToken);
    }

    public async Task NotifyNewWorkerPendingApprovalAsync(int workerId, CancellationToken cancellationToken = default)
    {
        var worker = await _context.Workers.AsNoTracking()
            .Include(w => w.Company)
            .FirstOrDefaultAsync(w => w.Id == workerId, cancellationToken);
        if (worker == null)
            return;

        var payload = NotificationTemplates.NewWorkerPendingApproval(
            workerId,
            worker.FullName,
            worker.Company?.Name ?? "—");
        await CreateForAllAdminsAsync(payload, skipIfDuplicate: true, cancellationToken);
    }

    public async Task NotifyCustomerReportAsync(int reportId, CancellationToken cancellationToken = default)
    {
        var report = await _context.Reports.AsNoTracking()
            .Include(r => r.Worker)
            .Include(r => r.Company)
            .FirstOrDefaultAsync(r => r.Id == reportId, cancellationToken);
        if (report == null)
            return;

        NotificationPayload payload = report.TargetType switch
        {
            ReportTargetType.Company => NotificationTemplates.CompanyReportedByCustomer(
                reportId, report.Company?.Name ?? "—"),
            ReportTargetType.Worker => NotificationTemplates.WorkerReportedByCustomer(
                reportId, report.Worker?.FullName ?? "—"),
            _ => throw new InvalidOperationException("Unknown report target type")
        };

        await CreateForAllAdminsAsync(payload, skipIfDuplicate: true, cancellationToken);
    }

    public async Task NotifyBookingReportCreatedAsync(int reportId, CancellationToken cancellationToken = default)
    {
        var report = await _context.BookingReports.AsNoTracking()
            .Include(r => r.Company)
            .FirstOrDefaultAsync(r => r.Id == reportId, cancellationToken);
        if (report == null)
            return;

        var adminPayload = NotificationTemplates.BookingReportSubmittedForAdmin(reportId);
        await CreateForAllAdminsAsync(adminPayload, skipIfDuplicate: true, cancellationToken);

        if (report.Company?.OwnerUserId is int ownerUserId)
        {
            var companyPayload = NotificationTemplates.BookingReportSubmittedForCompany(reportId);
            await CreateNotificationAsync(ownerUserId, companyPayload, skipIfDuplicate: true, cancellationToken);
        }
    }

    public async Task NotifyBookingReportStatusUpdatedAsync(int reportId, CancellationToken cancellationToken = default)
    {
        var report = await _context.BookingReports.AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == reportId, cancellationToken);
        if (report == null)
            return;

        var payload = NotificationTemplates.BookingReportStatusUpdatedForCustomer(reportId);
        await CreateNotificationAsync(report.CustomerId, payload, cancellationToken: cancellationToken);
    }

    public async Task NotifyBookingCreatedAsync(int bookingId, CancellationToken cancellationToken = default)
    {
        var booking = await LoadBookingContextAsync(bookingId, cancellationToken);
        if (booking == null)
            return;

        var customerName = booking.AppUser?.FullName ?? "—";
        var workerName = booking.Worker?.FullName ?? "—";

        var companyPayload = NotificationTemplates.BookingCreatedForCompany(bookingId, customerName, workerName);
        await CreateNotificationAsync(booking.Company!.OwnerUserId, companyPayload, cancellationToken: cancellationToken);

        var (type, titleEn, titleAr, msgEn, msgAr) = NotificationTemplates.MapBookingStatusForCustomer(BookingStatuses.Pending);
        var customerPayload = NotificationTemplates.BookingStatusForCustomer(
            bookingId, type, titleEn, titleAr,
            "Your booking has been submitted and is pending confirmation.",
            "تم إرسال حجزك وهو بانتظار التأكيد.");
        await CreateNotificationAsync(booking.UserId, customerPayload, cancellationToken: cancellationToken);
    }

    public async Task NotifyWorkerArrivalConfirmedAsync(int bookingId, CancellationToken cancellationToken = default)
    {
        var booking = await LoadBookingContextAsync(bookingId, cancellationToken);
        if (booking == null)
            return;

        var payload = NotificationTemplates.WorkerArrivalConfirmed(bookingId);
        await CreateNotificationAsync(booking.UserId, payload, cancellationToken: cancellationToken);
    }

    public async Task NotifyWalletAmountCapturedAsync(int bookingId, CancellationToken cancellationToken = default)
    {
        var booking = await LoadBookingContextAsync(bookingId, cancellationToken);
        if (booking == null)
            return;

        var payload = NotificationTemplates.WalletAmountCaptured(bookingId);
        await CreateNotificationAsync(booking.UserId, payload, cancellationToken: cancellationToken);
    }

    public async Task NotifyWalletReservationReleasedAsync(int bookingId, CancellationToken cancellationToken = default)
    {
        var booking = await LoadBookingContextAsync(bookingId, cancellationToken);
        if (booking == null)
            return;

        var payload = NotificationTemplates.WalletReservationReleased(bookingId);
        await CreateNotificationAsync(booking.UserId, payload, cancellationToken: cancellationToken);
    }

    public async Task NotifyWalletAmountRefundedAsync(int bookingId, CancellationToken cancellationToken = default)
    {
        var booking = await LoadBookingContextAsync(bookingId, cancellationToken);
        if (booking == null)
            return;

        var payload = NotificationTemplates.WalletAmountRefunded(bookingId);
        await CreateNotificationAsync(booking.UserId, payload, cancellationToken: cancellationToken);
    }

    public async Task NotifyBookingStatusChangedAsync(
        int bookingId,
        int previousStatus,
        int newStatus,
        CancellationToken cancellationToken = default)
    {
        if (previousStatus == newStatus)
            return;

        var booking = await LoadBookingContextAsync(bookingId, cancellationToken);
        if (booking == null)
            return;

        var customerName = booking.AppUser?.FullName ?? "—";
        var workerName = booking.Worker?.FullName ?? "—";

        var (custType, titleEn, titleAr, msgEn, msgAr) = NotificationTemplates.MapBookingStatusForCustomer(newStatus);
        if (newStatus == BookingStatuses.Rejected && !string.IsNullOrWhiteSpace(booking.RejectionReason))
        {
            msgEn += $" Reason: {booking.RejectionReason}";
            msgAr += $" السبب: {booking.RejectionReason}";
        }

        var customerPayload = NotificationTemplates.BookingStatusForCustomer(
            bookingId, custType, titleEn, titleAr, msgEn, msgAr);
        await CreateNotificationAsync(booking.UserId, customerPayload, cancellationToken: cancellationToken);

        var (compType, statusEn, statusAr) = NotificationTemplates.MapBookingStatusForCompany(newStatus);
        var companyPayload = NotificationTemplates.BookingStatusForCompanyOwner(
            bookingId, compType, customerName, workerName, statusEn, statusAr);
        await CreateNotificationAsync(booking.Company!.OwnerUserId, companyPayload, cancellationToken: cancellationToken);
    }

    public async Task CheckHealthCertificateExpirationsAsync(CancellationToken cancellationToken = default)
    {
        var today = DateTime.UtcNow.Date;
        var expiredWorkers = await _context.Workers.AsNoTracking()
            .Include(w => w.Company)
            .Where(w => w.IsActive && w.HealthCertificateExpiryDate.Date <= today)
            .ToListAsync(cancellationToken);

        foreach (var worker in expiredWorkers)
        {
            var adminPayload = NotificationTemplates.WorkerHealthCertificateExpiredAdmin(worker.Id, worker.FullName);
            await CreateForAllAdminsAsync(adminPayload, skipIfDuplicate: true, cancellationToken);

            if (worker.Company != null)
            {
                var ownerPayload = NotificationTemplates.WorkerHealthCertificateExpiredOwner(worker.Id, worker.FullName);
                await CreateNotificationAsync(
                    worker.Company.OwnerUserId,
                    ownerPayload,
                    skipIfDuplicate: true,
                    cancellationToken);
            }
        }
    }

    public Task ClearHealthExpiryNotificationsForWorkerAsync(int workerId, CancellationToken cancellationToken = default) =>
        _repository.SoftDeleteHealthExpiryForWorkerAsync(workerId, cancellationToken);

    public async Task<PagedResult<NotificationDTO>> GetUserNotificationsAsync(
        int userId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var paged = await _repository.GetUserNotificationsAsync(userId, pagination, cancellationToken);
        return PagedResult<NotificationDTO>.Create(
            paged.Items.Select(MapToDto).ToList(),
            paged.Page,
            paged.PageSize,
            paged.TotalCount);
    }

    public async Task<NotificationDTO?> GetNotificationByIdAsync(int id, int userId, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdForUserAsync(id, userId, cancellationToken);
        return entity == null ? null : MapToDto(entity);
    }

    public Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default) =>
        _repository.GetUnreadCountAsync(userId, cancellationToken);

    public async Task<bool> MarkAsReadAsync(int id, int userId, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdForUserAsync(id, userId, cancellationToken);
        if (entity == null)
            return false;

        if (!entity.IsRead)
            await _repository.MarkAsReadAsync(entity, cancellationToken);

        return true;
    }

    public Task<int> MarkAllAsReadAsync(int userId, CancellationToken cancellationToken = default) =>
        _repository.MarkAllAsReadAsync(userId, cancellationToken);

    public async Task<bool> SoftDeleteAsync(int id, int userId, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdForUserAsync(id, userId, cancellationToken);
        if (entity == null)
            return false;

        await _repository.SoftDeleteAsync(entity, cancellationToken);
        return true;
    }

    private async Task<List<int>> GetActiveAdminUserIdsAsync(CancellationToken cancellationToken)
    {
        var adminType = await _context.UserTypes.AsNoTracking()
            .FirstOrDefaultAsync(ut => ut.Name.ToLower() == AppRoles.Admin.ToLower(), cancellationToken);
        if (adminType == null)
            return [];

        return await _context.AppUsers.AsNoTracking()
            .Where(u => u.IsActive && u.UserTypeId == adminType.Id)
            .Select(u => u.Id)
            .ToListAsync(cancellationToken);
    }

    private async Task<Booking?> LoadBookingContextAsync(int bookingId, CancellationToken cancellationToken)
    {
        return await _context.Bookings.AsNoTracking()
            .Include(b => b.AppUser)
            .Include(b => b.Worker)
            .Include(b => b.Company)
            .FirstOrDefaultAsync(b => b.Id == bookingId, cancellationToken);
    }

    private NotificationDTO MapToDto(Notification entity)
    {
        var dto = _mapper.Map<NotificationDTO>(entity);
        dto.NotificationTypeName = entity.NotificationType.ToString();
        return dto;
    }
}

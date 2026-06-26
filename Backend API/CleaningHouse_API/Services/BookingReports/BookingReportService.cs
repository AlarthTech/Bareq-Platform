using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.BookingReports;

public class BookingReportService : IBookingReportService
{
    private readonly IBookingReportRepository _repository;
    private readonly INotificationService _notificationService;

    public BookingReportService(
        IBookingReportRepository repository,
        INotificationService notificationService)
    {
        _repository = repository;
        _notificationService = notificationService;
    }

    public async Task<(BookingReportResponse? Result, string? Error, int? StatusCode)> CreateReportAsync(
        int customerId,
        CreateBookingReportRequest request,
        CancellationToken cancellationToken = default)
    {
        var booking = await _repository.GetBookingForCustomerAsync(request.BookingId, customerId, cancellationToken);
        if (booking == null)
            return (null, "الحجز غير موجود أو لا يخصك.", 404);

        if (!BookingReportMapper.IsReportableBookingStatus(booking.Status))
            return (null, "لا يمكن تقديم بلاغ على حجز مكتمل أو ملغي.", 400);

        if (await _repository.HasActiveReportAsync(request.BookingId, customerId, cancellationToken))
            return (null, "يوجد بلاغ مفتوح بالفعل على هذا الحجز.", 400);

        var report = new BookingReport
        {
            BookingId = booking.Id,
            CustomerId = customerId,
            CompanyId = booking.CompanyId,
            WorkerId = booking.WorkerId,
            Reason = request.Reason.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            Status = BookingReportStatuses.Open,
            CreatedAt = DateTime.UtcNow
        };

        try
        {
            await _repository.AddAsync(report, cancellationToken);
        }
        catch (DbUpdateException)
        {
            return (null, "يوجد بلاغ مفتوح بالفعل على هذا الحجز.", 400);
        }

        var created = await _repository.GetDetailedByIdAsync(report.Id, cancellationToken);
        if (created == null)
            return (null, "تعذر تحميل البلاغ بعد الإنشاء.", 500);

        await _notificationService.NotifyBookingReportCreatedAsync(report.Id, cancellationToken);

        return (BookingReportMapper.ToResponse(created), null, null);
    }

    public async Task<PagedResult<BookingReportResponse>> GetMyReportsAsync(
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var paged = await _repository.GetCustomerReportsAsync(customerId, pagination, cancellationToken);
        return MapPaged(paged);
    }

    public async Task<(PagedResult<BookingReportResponse>? Result, string? Error, int? StatusCode)> GetReportsByBookingAsync(
        int customerId,
        int bookingId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var booking = await _repository.GetBookingForCustomerAsync(bookingId, customerId, cancellationToken);
        if (booking == null)
            return (null, "الحجز غير موجود أو لا يخصك.", 404);

        var paged = await _repository.GetReportsByBookingForCustomerAsync(bookingId, customerId, pagination, cancellationToken);
        return (MapPaged(paged), null, null);
    }

    public async Task<PagedResult<BookingReportResponse>> GetAllReportsAsync(
        BookingReportFilterParams filters,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var paged = await _repository.GetAdminReportsAsync(filters, pagination, cancellationToken: cancellationToken);
        return MapPaged(paged);
    }

    public async Task<(PagedResult<BookingReportResponse>? Result, string? Error, int? StatusCode)> GetCompanyReportsAsync(
        int companyOwnerUserId,
        BookingReportFilterParams filters,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var ownedCompanyIds = await _repository.GetOwnedCompanyIdsAsync(companyOwnerUserId, cancellationToken);
        if (ownedCompanyIds.Count == 0)
            return (MapPaged(PagedResult<BookingReport>.Create([], 1, pagination.PageSize, 0)), null, null);

        if (filters.CompanyId.HasValue && !ownedCompanyIds.Contains(filters.CompanyId.Value))
            return (null, "لا تملك صلاحية عرض بلاغات هذه الشركة.", 403);

        var paged = await _repository.GetAdminReportsAsync(
            filters,
            pagination,
            restrictToCompanyIds: ownedCompanyIds,
            cancellationToken: cancellationToken);

        return (MapPaged(paged), null, null);
    }

    public async Task<BookingReportResponse?> GetReportByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var report = await _repository.GetDetailedByIdAsync(id, cancellationToken);
        return report == null ? null : BookingReportMapper.ToResponse(report);
    }

    public async Task<(BookingReportResponse? Result, string? Error, int? StatusCode)> GetReportByIdForUserAsync(
        int reportId,
        int userId,
        bool isAdmin,
        CancellationToken cancellationToken = default)
    {
        if (!isAdmin && !await _repository.UserOwnsReportCompanyAsync(reportId, userId, cancellationToken))
            return (null, "لا تملك صلاحية عرض هذا البلاغ.", 403);

        var report = await GetReportByIdAsync(reportId, cancellationToken);
        if (report == null)
            return (null, "البلاغ غير موجود.", 404);

        return (report, null, null);
    }

    public async Task<(BookingReportResponse? Result, string? Error, int? StatusCode)> UpdateReportStatusAsync(
        int reportId,
        int resolverUserId,
        UpdateBookingReportStatusRequest request,
        bool isAdmin,
        CancellationToken cancellationToken = default)
    {
        var report = await _repository.GetByIdAsync(reportId, cancellationToken);
        if (report == null)
            return (null, "البلاغ غير موجود.", 404);

        if (!isAdmin && !await _repository.UserOwnsReportCompanyAsync(reportId, resolverUserId, cancellationToken))
            return (null, "لا تملك صلاحية تحديث هذا البلاغ.", 403);

        if (report.Status == request.Status)
            return (null, "البلاغ في هذه الحالة بالفعل.", 400);

        report.Status = request.Status;
        report.AdminResolutionNotes = string.IsNullOrWhiteSpace(request.AdminResolutionNotes)
            ? null
            : request.AdminResolutionNotes.Trim();
        report.UpdatedAt = DateTime.UtcNow;

        if (request.Status is BookingReportStatuses.Resolved or BookingReportStatuses.Rejected)
        {
            report.ResolvedByAdminId = resolverUserId;
            report.ResolvedAt = DateTime.UtcNow;
        }

        await _repository.SaveChangesAsync(cancellationToken);

        if (request.Status is BookingReportStatuses.Resolved or BookingReportStatuses.Rejected)
            await _notificationService.NotifyBookingReportStatusUpdatedAsync(reportId, cancellationToken);

        var updated = await _repository.GetDetailedByIdAsync(reportId, cancellationToken);
        return updated == null
            ? (null, "تعذر تحميل البلاغ بعد التحديث.", 500)
            : (BookingReportMapper.ToResponse(updated), null, null);
    }

    private static PagedResult<BookingReportResponse> MapPaged(PagedResult<BookingReport> paged) =>
        PagedResult<BookingReportResponse>.Create(
            paged.Items.Select(BookingReportMapper.ToResponse).ToList(),
            paged.Page,
            paged.PageSize,
            paged.TotalCount);
}

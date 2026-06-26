using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services.BookingReports;

public static class BookingReportMapper
{
    public static BookingReportResponse ToResponse(BookingReport report)
    {
        var bookingStatus = report.Booking?.Status ?? 0;

        return new BookingReportResponse
        {
            Id = report.Id,
            BookingId = report.BookingId,
            CustomerId = report.CustomerId,
            CustomerName = report.Customer?.FullName ?? "—",
            CompanyId = report.CompanyId,
            CompanyName = report.Company?.Name ?? "—",
            WorkerId = report.WorkerId,
            WorkerName = report.Worker?.FullName,
            Reason = report.Reason,
            Description = report.Description,
            Status = report.Status,
            StatusName = GetReportStatusName(report.Status),
            AdminResolutionNotes = report.AdminResolutionNotes,
            ResolvedByAdminId = report.ResolvedByAdminId,
            ResolvedByAdminName = report.ResolvedByAdmin?.FullName,
            ResolvedAt = report.ResolvedAt,
            CreatedAt = report.CreatedAt,
            UpdatedAt = report.UpdatedAt,
            BookingStatus = bookingStatus,
            BookingStatusName = GetBookingStatusName(bookingStatus)
        };
    }

    public static string GetReportStatusName(int status) =>
        status switch
        {
            BookingReportStatuses.Open => "مفتوح",
            BookingReportStatuses.InReview => "قيد المراجعة",
            BookingReportStatuses.Resolved => "تم الحل",
            BookingReportStatuses.Rejected => "مرفوض",
            _ => status.ToString()
        };

    public static string GetBookingStatusName(int status) =>
        status switch
        {
            BookingStatuses.Pending => "قيد الانتظار",
            BookingStatuses.Approved => "مؤكد",
            BookingStatuses.OnTheWay => "في الطريق",
            BookingStatuses.Completed => "مكتمل",
            BookingStatuses.Canceled => "ملغي",
            BookingStatuses.Rejected => "مرفوض",
            _ => status.ToString()
        };

    public static bool IsReportableBookingStatus(int status) =>
        status is BookingStatuses.Pending
            or BookingStatuses.Approved
            or BookingStatuses.OnTheWay
            or BookingStatuses.Rejected;
}

using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Customers;

namespace CleaningHouse_API.Services.BookingReports;

public interface IBookingReportService
{
    Task<(BookingReportResponse? Result, string? Error, int? StatusCode)> CreateReportAsync(
        int customerId,
        CreateBookingReportRequest request,
        CancellationToken cancellationToken = default);

    Task<PagedResult<BookingReportResponse>> GetMyReportsAsync(
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<(PagedResult<BookingReportResponse>? Result, string? Error, int? StatusCode)> GetReportsByBookingAsync(
        int customerId,
        int bookingId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<PagedResult<BookingReportResponse>> GetAllReportsAsync(
        BookingReportFilterParams filters,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<(PagedResult<BookingReportResponse>? Result, string? Error, int? StatusCode)> GetCompanyReportsAsync(
        int companyOwnerUserId,
        BookingReportFilterParams filters,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<BookingReportResponse?> GetReportByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<(BookingReportResponse? Result, string? Error, int? StatusCode)> GetReportByIdForUserAsync(
        int reportId,
        int userId,
        bool isAdmin,
        CancellationToken cancellationToken = default);

    Task<(BookingReportResponse? Result, string? Error, int? StatusCode)> UpdateReportStatusAsync(
        int reportId,
        int resolverUserId,
        UpdateBookingReportStatusRequest request,
        bool isAdmin,
        CancellationToken cancellationToken = default);
}

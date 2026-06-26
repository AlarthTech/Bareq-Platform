using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services.BookingReports;

public interface IBookingReportRepository
{
    Task<BookingReport?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<BookingReport?> GetDetailedByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<bool> HasActiveReportAsync(int bookingId, int customerId, CancellationToken cancellationToken = default);
    Task<Booking?> GetBookingForCustomerAsync(int bookingId, int customerId, CancellationToken cancellationToken = default);
    Task<BookingReport> AddAsync(BookingReport report, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<BookingReport>> GetCustomerReportsAsync(
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);
    Task<PagedResult<BookingReport>> GetReportsByBookingForCustomerAsync(
        int bookingId,
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);
    Task<PagedResult<BookingReport>> GetAdminReportsAsync(
        BookingReportFilterParams filters,
        PaginationParams pagination,
        IReadOnlyList<int>? restrictToCompanyIds = null,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<int>> GetOwnedCompanyIdsAsync(
        int ownerUserId,
        CancellationToken cancellationToken = default);

    Task<bool> UserOwnsReportCompanyAsync(
        int reportId,
        int ownerUserId,
        CancellationToken cancellationToken = default);
}

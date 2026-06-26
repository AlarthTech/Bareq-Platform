using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.BookingReports;

public class BookingReportRepository : IBookingReportRepository
{
    private readonly ApplicationDbContext _context;

    public BookingReportRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public Task<BookingReport?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        _context.BookingReports.FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

    public Task<BookingReport?> GetDetailedByIdAsync(int id, CancellationToken cancellationToken = default) =>
        BuildDetailedQuery().FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

    public Task<bool> HasActiveReportAsync(int bookingId, int customerId, CancellationToken cancellationToken = default) =>
        _context.BookingReports.AnyAsync(
            r => r.BookingId == bookingId
                && r.CustomerId == customerId
                && (r.Status == BookingReportStatuses.Open || r.Status == BookingReportStatuses.InReview),
            cancellationToken);

    public Task<Booking?> GetBookingForCustomerAsync(int bookingId, int customerId, CancellationToken cancellationToken = default) =>
        _context.Bookings.AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.UserId == customerId, cancellationToken);

    public async Task<BookingReport> AddAsync(BookingReport report, CancellationToken cancellationToken = default)
    {
        _context.BookingReports.Add(report);
        await _context.SaveChangesAsync(cancellationToken);
        return report;
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _context.SaveChangesAsync(cancellationToken);

    public async Task<PagedResult<BookingReport>> GetCustomerReportsAsync(
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var query = BuildDetailedQuery()
            .Where(r => r.CustomerId == customerId)
            .OrderByDescending(r => r.CreatedAt);

        return await query.ToPagedResultAsync(pagination, cancellationToken);
    }

    public async Task<PagedResult<BookingReport>> GetReportsByBookingForCustomerAsync(
        int bookingId,
        int customerId,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var query = BuildDetailedQuery()
            .Where(r => r.BookingId == bookingId && r.CustomerId == customerId)
            .OrderByDescending(r => r.CreatedAt);

        return await query.ToPagedResultAsync(pagination, cancellationToken);
    }

    public async Task<IReadOnlyList<int>> GetOwnedCompanyIdsAsync(
        int ownerUserId,
        CancellationToken cancellationToken = default)
    {
        var ids = await _context.Companies.AsNoTracking()
            .Where(c => c.OwnerUserId == ownerUserId)
            .Select(c => c.Id)
            .ToListAsync(cancellationToken);
        return ids;
    }

    public Task<bool> UserOwnsReportCompanyAsync(
        int reportId,
        int ownerUserId,
        CancellationToken cancellationToken = default) =>
        _context.BookingReports.AsNoTracking()
            .AnyAsync(
                r => r.Id == reportId
                    && _context.Companies.Any(c => c.Id == r.CompanyId && c.OwnerUserId == ownerUserId),
                cancellationToken);

    public async Task<PagedResult<BookingReport>> GetAdminReportsAsync(
        BookingReportFilterParams filters,
        PaginationParams pagination,
        IReadOnlyList<int>? restrictToCompanyIds = null,
        CancellationToken cancellationToken = default)
    {
        var query = BuildDetailedQuery();

        if (restrictToCompanyIds is { Count: > 0 })
            query = query.Where(r => restrictToCompanyIds.Contains(r.CompanyId));

        if (filters.Status.HasValue)
            query = query.Where(r => r.Status == filters.Status.Value);

        if (filters.BookingId.HasValue)
            query = query.Where(r => r.BookingId == filters.BookingId.Value);

        if (filters.CustomerId.HasValue)
            query = query.Where(r => r.CustomerId == filters.CustomerId.Value);

        if (filters.CompanyId.HasValue)
            query = query.Where(r => r.CompanyId == filters.CompanyId.Value);

        if (filters.WorkerId.HasValue)
            query = query.Where(r => r.WorkerId == filters.WorkerId.Value);

        if (filters.FromDate.HasValue)
            query = query.Where(r => r.CreatedAt >= filters.FromDate.Value);

        if (filters.ToDate.HasValue)
        {
            var endExclusive = filters.ToDate.Value.Date.AddDays(1);
            query = query.Where(r => r.CreatedAt < endExclusive);
        }

        query = query.OrderByDescending(r => r.CreatedAt);
        return await query.ToPagedResultAsync(pagination, cancellationToken);
    }

    private IQueryable<BookingReport> BuildDetailedQuery() =>
        _context.BookingReports.AsNoTracking()
            .Include(r => r.Booking)
            .Include(r => r.Customer)
            .Include(r => r.Company)
            .Include(r => r.Worker)
            .Include(r => r.ResolvedByAdmin);
}

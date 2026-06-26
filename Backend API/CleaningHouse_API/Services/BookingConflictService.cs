using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Customers;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services;

public class BookingConflictService : IBookingConflictService
{
    private const string SameCustomerMessage = "لديك حجز بالفعل مع هذه العاملة في هذا اليوم.";
    private const string WorkerBusyMessage = "العاملة محجوزة بالفعل في هذا اليوم.";

    private readonly ApplicationDbContext _context;

    public BookingConflictService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<BookingConflictResult> CheckCreateBookingConflictAsync(
        int workerId,
        int customerUserId,
        DateTime bookingDate,
        string startDate,
        string endDate,
        int? excludeBookingId = null,
        CancellationToken cancellationToken = default)
    {
        var targetDay = bookingDate.Date;
        var newBooking = new Booking
        {
            BookingDate = bookingDate,
            StartDate = startDate,
            EndDate = endDate
        };

        if (!BookingScheduleOverlap.CoversCalendarDay(newBooking, targetDay))
            return BookingConflictResult.None();

        var query = _context.Bookings
            .AsNoTracking()
            .Where(b => b.WorkerId == workerId
                && (b.Status == BookingStatuses.Pending
                    || b.Status == BookingStatuses.Approved
                    || b.Status == BookingStatuses.OnTheWay));

        if (excludeBookingId.HasValue)
            query = query.Where(b => b.Id != excludeBookingId.Value);

        var candidates = await query
            .Select(b => new { b.UserId, b.Status, b.BookingDate, b.StartDate, b.EndDate })
            .ToListAsync(cancellationToken);

        foreach (var existing in candidates)
        {
            var probe = new Booking
            {
                BookingDate = existing.BookingDate,
                StartDate = existing.StartDate,
                EndDate = existing.EndDate
            };

            if (!BookingScheduleOverlap.CoversCalendarDay(probe, targetDay))
                continue;

            if (existing.UserId == customerUserId)
                return BookingConflictResult.Conflict(SameCustomerMessage);

            if (existing.Status is BookingStatuses.Approved or BookingStatuses.OnTheWay)
                return BookingConflictResult.Conflict(WorkerBusyMessage);
        }

        return BookingConflictResult.None();
    }

    public async Task<HashSet<int>> GetWorkerIdsBusyOnDayAsync(
        DateTime calendarDay,
        CancellationToken cancellationToken = default)
    {
        var targetDay = calendarDay.Date;

        var activeBookings = await _context.Bookings
            .AsNoTracking()
            .Where(b => b.Status == BookingStatuses.Approved
                || b.Status == BookingStatuses.OnTheWay)
            .Select(b => new { b.WorkerId, b.BookingDate, b.StartDate, b.EndDate })
            .ToListAsync(cancellationToken);

        var busy = new HashSet<int>();
        foreach (var b in activeBookings)
        {
            var probe = new Booking
            {
                BookingDate = b.BookingDate,
                StartDate = b.StartDate,
                EndDate = b.EndDate
            };
            if (BookingScheduleOverlap.CoversCalendarDay(probe, targetDay))
                busy.Add(b.WorkerId);
        }

        return busy;
    }
}

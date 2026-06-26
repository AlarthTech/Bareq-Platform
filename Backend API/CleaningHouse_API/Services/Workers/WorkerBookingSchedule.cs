using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services.Workers;

internal readonly record struct WorkerBookingSchedule(
    int WorkerId,
    DateTime BookingDate,
    string StartDate,
    string EndDate)
{
    public Booking ToBooking() => new()
    {
        BookingDate = BookingDate,
        StartDate = StartDate,
        EndDate = EndDate
    };
}

internal static class WorkerAvailabilityCalculator
{
    private const int BookingLookupWindowDays = 90;
    private const int NextAvailableSearchDays = 366;

    public static HashSet<int> GetBusyWorkerIdsForDay(
        IEnumerable<WorkerBookingSchedule> activeBookings,
        DateTime calendarDay)
    {
        var busy = new HashSet<int>();
        foreach (var schedule in activeBookings)
        {
            if (BookingScheduleOverlap.CoversCalendarDay(schedule.ToBooking(), calendarDay))
                busy.Add(schedule.WorkerId);
        }

        return busy;
    }

    public static HashSet<DateTime> GetBusyCalendarDays(IEnumerable<WorkerBookingSchedule> activeBookings)
    {
        var days = new HashSet<DateTime>();
        foreach (var schedule in activeBookings)
        {
            var (start, end) = BookingScheduleOverlap.ResolveBookingDateRange(schedule.ToBooking());
            for (var d = start.Date; d <= end.Date; d = d.AddDays(1))
                days.Add(d);
        }

        return days;
    }

    public static DateOnly? FindNextAvailableDate(HashSet<DateTime> busyDays, DateOnly fromDate)
    {
        var cursor = fromDate.ToDateTime(TimeOnly.MinValue);
        var limit = cursor.AddDays(NextAvailableSearchDays);

        while (cursor < limit)
        {
            if (!busyDays.Contains(cursor.Date))
                return DateOnly.FromDateTime(cursor.Date);

            cursor = cursor.AddDays(1);
        }

        return null;
    }

    public static (DateTime WindowStart, DateTime WindowEnd) BookingLookupWindow(DateTime centerDay) =>
        (centerDay.Date.AddDays(-BookingLookupWindowDays), centerDay.Date.AddDays(BookingLookupWindowDays));
}

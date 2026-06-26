using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services;

public static class BookingScheduleOverlap
{
    public static DateTime? TryParseDateOnly(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        if (DateTime.TryParse(value, out var parsed))
            return parsed.Date;

        return null;
    }

    public static (DateTime Start, DateTime End) ResolveBookingDateRange(Booking booking)
    {
        var start = TryParseDateOnly(booking.StartDate) ?? booking.BookingDate.Date;
        var end = TryParseDateOnly(booking.EndDate) ?? start;
        if (end < start)
            (start, end) = (end, start);
        return (start, end);
    }

    public static bool RangesOverlap(DateTime startA, DateTime endA, DateTime startB, DateTime endB) =>
        startA <= endB && startB <= endA;

    public static bool Overlaps(Booking existing, DateTime newStart, DateTime newEnd)
    {
        var (existingStart, existingEnd) = ResolveBookingDateRange(existing);
        return RangesOverlap(existingStart, existingEnd, newStart, newEnd);
    }

    public static bool CoversCalendarDay(Booking booking, DateTime calendarDay)
    {
        var day = calendarDay.Date;
        var (start, end) = ResolveBookingDateRange(booking);
        return day >= start.Date && day <= end.Date;
    }
}

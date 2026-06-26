using System.Globalization;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services;

public static class BookingScheduleParser
{
    /// <summary>
    /// Resolves the scheduled end instant in UTC using <see cref="Booking.BookingDate"/> and <see cref="Booking.EndDate"/>.
    /// If <see cref="Booking.EndDate"/> parses to a date with no time, the end of that calendar day (local) is used.
    /// </summary>
    public static DateTime? GetScheduledEndUtc(Booking booking)
    {
        var endRaw = booking.EndDate?.Trim();
        if (string.IsNullOrEmpty(endRaw))
            return null;

        var bookingLocalDay = booking.BookingDate.Kind == DateTimeKind.Utc
            ? booking.BookingDate.ToLocalTime().Date
            : booking.BookingDate.Date;

        if (DateTime.TryParse(
                endRaw,
                CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeLocal | DateTimeStyles.AllowWhiteSpaces,
                out var endLocal))
        {
            if (endLocal.TimeOfDay == TimeSpan.Zero)
                endLocal = endLocal.Date.AddDays(1).AddTicks(-1);

            if (endLocal.Kind == DateTimeKind.Unspecified)
                endLocal = DateTime.SpecifyKind(endLocal, DateTimeKind.Local);

            return endLocal.ToUniversalTime();
        }

        if (TimeSpan.TryParse(endRaw, CultureInfo.InvariantCulture, out var timeOfDay))
        {
            var combined = DateTime.SpecifyKind(bookingLocalDay.Add(timeOfDay), DateTimeKind.Local);
            return combined.ToUniversalTime();
        }

        return null;
    }
}

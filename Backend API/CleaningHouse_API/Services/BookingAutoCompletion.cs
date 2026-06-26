using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services;

public static class BookingAutoCompletion
{
    public sealed record CompletedBooking(int BookingId, int PreviousStatus);

    /// <summary>
    /// Marks due approved/on-the-way bookings as completed. Returns affected bookings for notifications.
    /// </summary>
    public static async Task<IReadOnlyList<CompletedBooking>> CompleteDueBookingsAsync(
        ApplicationDbContext db,
        CancellationToken cancellationToken = default)
    {
        var candidates = await db.Bookings
            .Where(b => b.Status == BookingStatuses.Approved || b.Status == BookingStatuses.OnTheWay)
            .ToListAsync(cancellationToken);

        if (candidates.Count == 0)
            return Array.Empty<CompletedBooking>();

        var now = DateTime.UtcNow;
        var completed = new List<CompletedBooking>();

        foreach (var booking in candidates)
        {
            var endUtc = BookingScheduleParser.GetScheduledEndUtc(booking);
            if (endUtc is null || now < endUtc.Value)
                continue;

            var previous = booking.Status;
            booking.Status = BookingStatuses.Completed;
            booking.RejectionReason = null;
            completed.Add(new CompletedBooking(booking.Id, previous));
        }

        if (completed.Count > 0)
            await db.SaveChangesAsync(cancellationToken);

        return completed;
    }
}

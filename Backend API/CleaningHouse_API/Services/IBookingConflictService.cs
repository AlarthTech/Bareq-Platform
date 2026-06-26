namespace CleaningHouse_API.Services;

public interface IBookingConflictService
{
    /// <summary>
    /// Validates whether a new customer booking is allowed for the worker on the requested day.
    /// Blocks: same customer already booked that worker that day; worker has approved or on-the-way that day.
    /// Pending bookings from other customers do not block.
    /// </summary>
    Task<BookingConflictResult> CheckCreateBookingConflictAsync(
        int workerId,
        int customerUserId,
        DateTime bookingDate,
        string startDate,
        string endDate,
        int? excludeBookingId = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Worker ids that cannot accept new bookings on the given calendar day (approved or on the way).
    /// </summary>
    Task<HashSet<int>> GetWorkerIdsBusyOnDayAsync(
        DateTime calendarDay,
        CancellationToken cancellationToken = default);
}

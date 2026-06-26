namespace CleaningHouse_API.Models.Customers;

/// <summary>
/// Booking lifecycle: 0 pending → 1 approved → 2 on the way → 3 completed;
/// 4 canceled (from pending only); 5 rejected by company (from pending only).
/// </summary>
public static class BookingStatuses
{
    public const int Pending = 0;
    public const int Approved = 1;
    public const int OnTheWay = 2;
    public const int Completed = 3;
    public const int Canceled = 4;
    public const int Rejected = 5;

    public static bool ReservesWorker(int status) =>
        status is Pending or Approved or OnTheWay;

    public static bool IsTerminal(int status) =>
        status is Completed or Canceled or Rejected;
}

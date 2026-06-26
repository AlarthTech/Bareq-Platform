namespace CleaningHouse_API.Models.Customers;

public static class BookingReportStatuses
{
    public const int Open = 0;
    public const int InReview = 1;
    public const int Resolved = 2;
    public const int Rejected = 3;

    public static bool IsActive(int status) =>
        status is Open or InReview;

    public static bool IsTerminal(int status) =>
        status is Resolved or Rejected;

    public static bool IsValidAdminUpdateTarget(int status) =>
        status is InReview or Resolved or Rejected;
}

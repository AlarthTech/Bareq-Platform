using System.Globalization;

namespace CleaningHouse_API.Services.Workers;

public static class WorkerAvailabilityLabels
{
    private static readonly CultureInfo LabelCulture = CultureInfo.GetCultureInfo("en-US");

    public static string ForDate(DateOnly date, DateOnly today)
    {
        if (date == today)
            return "Available Today";

        return $"Available on {date.ToString("MMM dd, yyyy", LabelCulture)}";
    }

    public static DateOnly TodayUtc() => DateOnly.FromDateTime(DateTime.UtcNow.Date);
}

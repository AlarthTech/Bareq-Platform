namespace CleaningHouse_API.Services;

public sealed class BookingConflictResult
{
    public bool HasConflict { get; init; }
    public string? Detail { get; init; }

    public static BookingConflictResult None() => new() { HasConflict = false };

    public static BookingConflictResult Conflict(string detail) =>
        new() { HasConflict = true, Detail = detail };
}

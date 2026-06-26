namespace CleaningHouse_API.DTOs.Companies;

/// <summary>Home screen worker card — shared by available and top-rated endpoints.</summary>
public class WorkerCardDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CompanyId { get; set; }
    public string? CompanyName { get; set; }
    public string? ProfileImageUrl { get; set; }
    public double Rating { get; set; }
    public int ReviewCount { get; set; }

    public bool? IsAvailable { get; set; }
    public bool? IsAvailableToday { get; set; }

    public DateOnly? AvailableDate { get; set; }
    public DateOnly? NextAvailableDate { get; set; }

    public string AvailabilityLabel { get; set; } = string.Empty;
}

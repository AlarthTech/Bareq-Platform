using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Customers;

public class ReviewDTO
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public int UserId { get; set; }
    public string? UserName { get; set; }
    public int WorkerId { get; set; }
    public string? WorkerName { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateReviewDTO
{
    [Required]
    public int BookingId { get; set; }

    [Required]
    public int WorkerId { get; set; }

    [Required]
    [Range(1, 5)]
    public int Rating { get; set; }

    [MaxLength(1000)]
    public string? Comment { get; set; }
}

public class UpdateReviewDTO
{
    [Range(1, 5)]
    public int? Rating { get; set; }

    [MaxLength(1000)]
    public string? Comment { get; set; }
}

public class RatingSummaryDTO
{
    public double AverageRating { get; set; }
    public int TotalReviews { get; set; }
}

public class WorkerRatingSummaryDTO : RatingSummaryDTO
{
    public int WorkerId { get; set; }
}

public class CompanyRatingSummaryDTO : RatingSummaryDTO
{
    public int CompanyId { get; set; }
    public int RatedWorkersCount { get; set; }
    public int TotalActiveWorkers { get; set; }
}

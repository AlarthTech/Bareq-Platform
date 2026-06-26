using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Customers;

public class FavoriteDTO
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string? UserName { get; set; }
    public int WorkerId { get; set; }
    public string? WorkerName { get; set; }
    public string? WorkerProfileImage { get; set; }
    public int? CompanyId { get; set; }
    public string? CompanyName { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateFavoriteDTO
{
    [Required]
    public int WorkerId { get; set; }
}


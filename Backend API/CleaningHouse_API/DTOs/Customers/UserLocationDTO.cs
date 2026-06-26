using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Customers;

public class UserLocationDTO
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string LocationName { get; set; } = string.Empty;
    public double Lat { get; set; }
    public double Lng { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateUserLocationDTO
{
    [Required]
    [MaxLength(200)]
    public string LocationName { get; set; } = string.Empty;

    [Required]
    public double Lat { get; set; }

    [Required]
    public double Lng { get; set; }
}

public class UpdateUserLocationDTO
{
    [MaxLength(200)]
    public string? LocationName { get; set; }

    public double? Lat { get; set; }

    public double? Lng { get; set; }
}

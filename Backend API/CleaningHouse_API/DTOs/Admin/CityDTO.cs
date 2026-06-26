using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Admin;

public class CityDTO
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public bool IsActive { get; set; }
}

public class CreateCityDTO
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(10)]
    public string? Code { get; set; }

    public bool IsActive { get; set; } = true;
}

public class UpdateCityDTO
{
    [MaxLength(100)]
    public string? Name { get; set; }

    [MaxLength(10)]
    public string? Code { get; set; }

    public bool? IsActive { get; set; }
}




















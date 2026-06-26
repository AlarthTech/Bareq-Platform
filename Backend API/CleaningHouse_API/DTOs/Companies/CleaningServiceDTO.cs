using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Companies;

public class CleaningServiceDTO
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class CreateCleaningServiceDTO
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }
}

public class UpdateCleaningServiceDTO
{
    [MaxLength(200)]
    public string? Name { get; set; }

    [MaxLength(1000)]
    public string? Description { get; set; }
}




















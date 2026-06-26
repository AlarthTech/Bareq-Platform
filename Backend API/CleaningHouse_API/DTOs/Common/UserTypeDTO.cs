using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Common;

public class UserTypeDTO
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class CreateUserTypeDTO
{
    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? Description { get; set; }
}

public class UpdateUserTypeDTO
{
    [MaxLength(50)]
    public string? Name { get; set; }

    [MaxLength(200)]
    public string? Description { get; set; }
}








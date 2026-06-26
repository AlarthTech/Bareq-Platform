using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Companies;

public class CompanyDTO
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? CommercialRegNo { get; set; }
    /// <summary>رابط ملف السجل التجاري</summary>
    public string? CommercialRegisterURL { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int OwnerUserId { get; set; }
    public string? OwnerUserName { get; set; }
    public int CityId { get; set; }
    public string? CityName { get; set; }
    public int ExperienceYears { get; set; }
    public string? Description { get; set; }
    public bool IsVerified { get; set; }


    public DateTime CreatedAt { get; set; }
}

public class CreateCompanyDTO
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Address { get; set; }

    [MaxLength(50)]
    public string? CommercialRegNo { get; set; }

    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    // CommercialRegisterURL يُعيَّن تلقائياً من endpoint رفع الملف، لا يُرسل في Create

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public int OwnerUserId { get; set; }

    [Required]
    public int CityId { get; set; }

    [Range(0, 100)]
    public int ExperienceYears { get; set; } = 0;

    [MaxLength(2000)]
    public string? Description { get; set; }
}

public class UpdateCompanyDTO
{
    [MaxLength(200)]
    public string? Name { get; set; }

    [MaxLength(500)]
    public string? Address { get; set; }

    [MaxLength(50)]
    public string? CommercialRegNo { get; set; }

    [MaxLength(500)]
    public string? CommercialRegisterURL { get; set; }

    [MaxLength(100)]
    [EmailAddress]
    public string? Email { get; set; }
    public int? CityId { get; set; }
    [Range(0, 100)]
    public int? ExperienceYears { get; set; }
    [MaxLength(2000)]
    public string? Description { get; set; }
}






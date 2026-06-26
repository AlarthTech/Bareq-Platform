using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Companies;

public class WorkerDTO
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public string? CompanyName { get; set; }
    public string FullName { get; set; } = string.Empty;
    public int NationalityId { get; set; }
    public string? NationalityName { get; set; }
    public int Age { get; set; }
    public int ExperienceYears { get; set; }
    public bool IsAvailable { get; set; }
    public string? ProfileImage { get; set; }
    public string HealthCertificate { get; set; } = string.Empty;
    /// <summary>رابط صورة شهادة صحية</summary>
    public string? HealthCertificateURL { get; set; }
    public DateTime HealthCertificateExpiryDate { get; set; }
    public string? LanguagesIds { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateWorkerDTO
{
    [Required]
    public int CompanyId { get; set; }

    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    public int NationalityId { get; set; }

    [Required]
    [Range(18, 100)]
    public int Age { get; set; }

    [Range(0, 50)]
    public int ExperienceYears { get; set; } = 0;

    public bool IsAvailable { get; set; } = true;

    [MaxLength(500)]
    public string? ProfileImage { get; set; }

    [Required]
    [MaxLength(500)]
    public string HealthCertificate { get; set; } = string.Empty;

    // HealthCertificateURL يُعيَّن من endpoint رفع الصورة

    [Required]
    public DateTime HealthCertificateExpiryDate { get; set; }

    [MaxLength(200)]
    public string? LanguagesIds { get; set; }
}

/// <summary>لا يتضمن isActive, isAvailable, profileImage, healthCertificate — لا تُعدّل من هذا الـ API.</summary>
public class UpdateWorkerDTO
{
    [MaxLength(200)]
    public string? FullName { get; set; }

    public int? NationalityId { get; set; }

    [Range(18, 100)]
    public int? Age { get; set; }

    [Range(0, 50)]
    public int? ExperienceYears { get; set; }

    [MaxLength(500)]
    public string? HealthCertificateURL { get; set; }

    public DateTime? HealthCertificateExpiryDate { get; set; }

    [MaxLength(200)]
    public string? LanguagesIds { get; set; }
}

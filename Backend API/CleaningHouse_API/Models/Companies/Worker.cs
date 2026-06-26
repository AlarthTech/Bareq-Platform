using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Admin;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Models.Companies;

[Table("Workers")]
public class Worker
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int CompanyId { get; set; }

    [Required] 
    public string FullName { get; set; } = string.Empty;

    public int NationalityId { get; set; }

    public int Age { get; set; }

    public int ExperienceYears { get; set; }

    public bool IsAvailable { get; set; } = false;

    [MaxLength(500)]
    public string? ProfileImage { get; set; }

    [MaxLength(500)]
    public string HealthCertificate { get; set; } = string.Empty; // شهادة الصحية مرفق

    /// <summary>رابط صورة شهادة صحية (يُخزَّن بعد رفع الملف)</summary>
    [MaxLength(500)]
    public string? HealthCertificateURL { get; set; }

    public DateTime HealthCertificateExpiryDate { get; set; } // تاريخ صلاحية الشهادة الصحية

    [MaxLength(200)]
    public string? LanguagesIds { get; set; } // معرفات اللغات مفصولة بفواصل (مثل: "1,2,3")

    public bool IsActive { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("CompanyId")]
    public virtual Company? Company { get; set; }

    [ForeignKey("NationalityId")]
    public virtual Nationality? Nationality { get; set; }

    public virtual ICollection<Booking>? Bookings { get; set; }
    public virtual ICollection<Review>? Reviews { get; set; }
    public virtual ICollection<WorkerWorkType>? WorkerWorkTypes { get; set; }
    public virtual ICollection<Favorite>? Favorites { get; set; }
}


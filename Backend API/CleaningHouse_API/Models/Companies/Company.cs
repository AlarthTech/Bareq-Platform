using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Models.Admin;

namespace CleaningHouse_API.Models.Companies;

[Table("Companies")]
public class Company
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    public string? Address { get; set; }

    [MaxLength(50)]
    public string? CommercialRegNo { get; set; }

    [Required] 
    public string Phone { get; set; } = string.Empty;

    [Required]
    public string Email { get; set; } = string.Empty;

    [Required]
    public int OwnerUserId { get; set; }

    [Required]
    public int CityId { get; set; }

    [Range(0, 100)]
    public int ExperienceYears { get; set; } = 0; // سنوات الخبرة للشركة

    [MaxLength(2000)]
    public string? Description { get; set; } // وصف عن الشركة

    /// <summary>رابط ملف السجل التجاري (يُخزَّن بعد رفع الملف)</summary>
    [MaxLength(500)]
    public string? CommercialRegisterURL { get; set; }

    public bool IsVerified { get; set; } = false;

    public bool IsActive { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("OwnerUserId")]
    public virtual AppUser? OwnerAppUser { get; set; }

    [ForeignKey("CityId")]
    public virtual City? City { get; set; }

    public virtual ICollection<Worker>? Workers { get; set; }
    public virtual ICollection<Booking>? Bookings { get; set; }
    public virtual ICollection<WorkType>? WorkTypes { get; set; }
}


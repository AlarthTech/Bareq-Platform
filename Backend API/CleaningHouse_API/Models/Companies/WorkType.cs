using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Companies;

[Table("WorkTypes")]
public class WorkType
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty; // اسم التصنيف (مثل: عمل يوم عادي، عمل في المناسبات)

    [Required]
    public int CompanyId { get; set; } // الشركة التي تملك هذا التصنيف

    [Required]
    [MaxLength(50)]
    public string StartTime { get; set; } = string.Empty; // وقت بداية الدوام (مثل: 08:00)

    [Required]
    [MaxLength(50)]
    public string EndTime { get; set; } = string.Empty; // وقت نهاية الدوام (مثل: 18:00)

    public bool IsOvernight { get; set; } = false; // هل العمل يمتد إلى اليوم التالي (مثل: من 8 صباحاً إلى 8 صباحاً اليوم التالي)

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Price { get; set; }   // سعر هذا التصنيف

    [Column(TypeName = "decimal(18,2)")]
    public decimal? MonthlyPrice { get; set; } // خيار سعر شهري لهذا التصنيف

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("CompanyId")]
    public virtual Company? Company { get; set; }

    public virtual ICollection<WorkerWorkType>? WorkerWorkTypes { get; set; }
}


using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Models.Admin;

[Table("CommissionSettings")]
public class CommissionSetting
{
    [Key]
    public int Id { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal FixedPlatformFeeAmount { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public int? UpdatedByAdminId { get; set; }

    [ForeignKey(nameof(UpdatedByAdminId))]
    public virtual AppUser? UpdatedByAdmin { get; set; }
}

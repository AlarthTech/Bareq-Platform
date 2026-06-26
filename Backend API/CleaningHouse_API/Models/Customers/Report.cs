using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;

namespace CleaningHouse_API.Models.Customers;

[Table("Reports")]
public class Report
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    public ReportTargetType TargetType { get; set; }

    public int? WorkerId { get; set; }

    public int? CompanyId { get; set; }

    [Required]
    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;

    public ReportStatus Status { get; set; } = ReportStatus.Pending;

    [MaxLength(2000)]
    public string? AdminNotes { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey(nameof(UserId))]
    public virtual AppUser? AppUser { get; set; }

    [ForeignKey(nameof(WorkerId))]
    public virtual Worker? Worker { get; set; }

    [ForeignKey(nameof(CompanyId))]
    public virtual Company? Company { get; set; }
}

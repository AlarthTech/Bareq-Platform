using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;

namespace CleaningHouse_API.Models.Customers;

[Table("BookingReports")]
public class BookingReport
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [Required]
    public int CustomerId { get; set; }

    [Required]
    public int CompanyId { get; set; }

    public int? WorkerId { get; set; }

    [Required]
    [MaxLength(200)]
    public string Reason { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    [Required]
    public int Status { get; set; } = BookingReportStatuses.Open;

    [MaxLength(1000)]
    public string? AdminResolutionNotes { get; set; }

    public int? ResolvedByAdminId { get; set; }

    public DateTime? ResolvedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey(nameof(BookingId))]
    public virtual Booking? Booking { get; set; }

    [ForeignKey(nameof(CustomerId))]
    public virtual AppUser? Customer { get; set; }

    [ForeignKey(nameof(CompanyId))]
    public virtual Company? Company { get; set; }

    [ForeignKey(nameof(WorkerId))]
    public virtual Worker? Worker { get; set; }

    [ForeignKey(nameof(ResolvedByAdminId))]
    public virtual AppUser? ResolvedByAdmin { get; set; }
}

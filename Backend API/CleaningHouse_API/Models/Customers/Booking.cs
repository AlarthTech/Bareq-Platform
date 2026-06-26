using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;

namespace CleaningHouse_API.Models.Customers;

[Table("Bookings")]
public class Booking
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    public int CompanyId { get; set; }

    [Required]
    public int WorkerId { get; set; }
    
    [Required]
    public int WorkTypeId { get; set; }

    [Required]
    public DateTime BookingDate { get; set; }

    [Required]
    [MaxLength(50)]
    public string StartDate { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string EndDate { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string Address { get; set; } = string.Empty;

    public int? UserLocationId { get; set; }

    [Required]
    public int Status { get; set; }

    [MaxLength(2000)]
    public string? RejectionReason { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal ServicePrice { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal PlatformFeeAmount { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalPrice { get; set; }

    public bool IsMonthlyPricing { get; set; }

    public bool IsWorkerArrivalConfirmed { get; set; }

    public DateTime? WorkerArrivalConfirmedAt { get; set; }

    public bool WalletAmountReserved { get; set; }

    public bool WalletAmountCaptured { get; set; }

    public DateTime? WalletCapturedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("UserId")]
    public virtual AppUser? AppUser { get; set; }

    [ForeignKey("CompanyId")]
    public virtual Company? Company { get; set; }

    [ForeignKey("WorkerId")]
    public virtual Worker? Worker { get; set; }
    
    [ForeignKey("WorkTypeId")]
    public virtual WorkType? WorkType { get; set; }

    [ForeignKey(nameof(UserLocationId))]
    public virtual UserLocation? UserLocation { get; set; }

    public virtual ICollection<Payment>? Payments { get; set; }
    public virtual ICollection<Review>? Reviews { get; set; }
}




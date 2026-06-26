using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Models.Wallet;

[Table("WalletTransactions")]
public class WalletTransaction
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int WalletId { get; set; }

    [Required]
    public int CustomerId { get; set; }

    public int? BookingId { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    [Required]
    [MaxLength(50)]
    public string Type { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Direction { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = WalletTransactionStatuses.Pending;

    [Required]
    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? ReferenceNumber { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }

    public int? CreatedByAdminId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }

    [ForeignKey(nameof(WalletId))]
    public virtual Wallet? Wallet { get; set; }

    [ForeignKey(nameof(CustomerId))]
    public virtual AppUser? Customer { get; set; }

    [ForeignKey(nameof(BookingId))]
    public virtual Booking? Booking { get; set; }

    [ForeignKey(nameof(CreatedByAdminId))]
    public virtual AppUser? CreatedByAdmin { get; set; }
}

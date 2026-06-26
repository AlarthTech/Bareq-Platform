using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Models.Wallet;

[Table("WalletTopUpRequests")]
public class WalletTopUpRequest
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int CustomerId { get; set; }

    [Required]
    public int WalletId { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal RequestedAmount { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal? ApprovedAmount { get; set; }

    [Required]
    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = WalletTopUpStatuses.Pending;

    [MaxLength(100)]
    public string? TransferReferenceNumber { get; set; }

    [MaxLength(500)]
    public string? TransferReceiptImageUrl { get; set; }

    [MaxLength(100)]
    public string? GatewayPaymentReference { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }

    [MaxLength(500)]
    public string? AdminNotes { get; set; }

    [MaxLength(500)]
    public string? RejectionReason { get; set; }

    public int? ReviewedByAdminId { get; set; }

    public DateTime? ReviewedAt { get; set; }

    public int? WalletTransactionId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }

    [ForeignKey(nameof(CustomerId))]
    public virtual AppUser? Customer { get; set; }

    [ForeignKey(nameof(WalletId))]
    public virtual Wallet? Wallet { get; set; }

    [ForeignKey(nameof(ReviewedByAdminId))]
    public virtual AppUser? ReviewedByAdmin { get; set; }

    [ForeignKey(nameof(WalletTransactionId))]
    public virtual WalletTransaction? WalletTransaction { get; set; }
}

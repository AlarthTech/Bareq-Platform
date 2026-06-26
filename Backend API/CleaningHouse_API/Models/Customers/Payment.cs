using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Customers;

[Table("Payments")]
public class Payment
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [Required]
    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal? WalletFeeAmount { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal? BookingTotalAmount { get; set; }

    public int WalletRefundStatus { get; set; }

    [Required]
    public int PaymentStatus { get; set; }

    public DateTime? PaidAt { get; set; }

    [MaxLength(200)]
    public string? TransactionId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(BookingId))]
    public virtual Booking? Booking { get; set; }
}

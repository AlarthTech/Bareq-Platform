using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Models.Wallet;

[Table("Wallets")]
public class Wallet
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int CustomerId { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Balance { get; set; }

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal ReservedBalance { get; set; }

    [Required]
    [MaxLength(10)]
    public string Currency { get; set; } = "LYD";

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [Timestamp]
    public byte[] RowVersion { get; set; } = Array.Empty<byte>();

    [ForeignKey(nameof(CustomerId))]
    public virtual AppUser? Customer { get; set; }

    public virtual ICollection<WalletTransaction>? Transactions { get; set; }
}

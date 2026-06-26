using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Models.Wallet;

[Table("WalletPaymentSettings")]
public class WalletPaymentSettings
{
    [Key]
    public int Id { get; set; }

    public bool IsWalletPaymentEnabled { get; set; }

    [Column(TypeName = "decimal(5,2)")]
    public decimal WalletPaymentFeePercentage { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public int? UpdatedByAdminId { get; set; }

    [ForeignKey(nameof(UpdatedByAdminId))]
    public virtual AppUser? UpdatedByAdmin { get; set; }
}

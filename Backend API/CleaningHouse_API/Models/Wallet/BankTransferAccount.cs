using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Wallet;

[Table("BankTransferAccounts")]
public class BankTransferAccount
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string BankName { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string AccountHolderName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string AccountNumber { get; set; } = string.Empty;

    [MaxLength(50)]
    public string? Iban { get; set; }

    [MaxLength(200)]
    public string? BranchName { get; set; }

    [MaxLength(1000)]
    public string? Instructions { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

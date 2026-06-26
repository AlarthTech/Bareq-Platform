using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Common;

[Table("PasswordResetTokens")]
public class PasswordResetToken
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    [MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? CodeHash { get; set; }

    [MaxLength(200)]
    public string? ResetTokenHash { get; set; }

    public DateTime? CodeExpiresAt { get; set; }

    public DateTime? ResetTokenExpiresAt { get; set; }

    public DateTime? VerifiedAt { get; set; }

    public DateTime? UsedAt { get; set; }

    public int FailedAttempts { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [MaxLength(64)]
    public string? IpAddress { get; set; }

    [MaxLength(512)]
    public string? UserAgent { get; set; }

    [ForeignKey(nameof(UserId))]
    public virtual AppUser? AppUser { get; set; }
}

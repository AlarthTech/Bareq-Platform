using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Common;

[Table("ExternalLogins")]
public class ExternalLogin
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int AppUserId { get; set; }

    [Required]
    public ExternalAuthProvider Provider { get; set; }

    [Required]
    [MaxLength(256)]
    public string ProviderUserId { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(AppUserId))]
    public virtual AppUser? AppUser { get; set; }
}

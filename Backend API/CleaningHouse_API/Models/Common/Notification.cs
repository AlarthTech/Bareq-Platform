using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Common;

[Table("Notifications")]
public class Notification
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    [MaxLength(256)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(256)]
    public string TitleAr { get; set; } = string.Empty;

    [Required]
    [MaxLength(2000)]
    public string Message { get; set; } = string.Empty;

    [Required]
    [MaxLength(2000)]
    public string MessageAr { get; set; } = string.Empty;

    [Required]
    public NotificationType NotificationType { get; set; }

    public int? RelatedEntityId { get; set; }

    public bool IsRead { get; set; }

    public bool IsDeleted { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserId))]
    public virtual AppUser? AppUser { get; set; }
}

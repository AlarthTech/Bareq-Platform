using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;

namespace CleaningHouse_API.Models.Customers;

[Table("Reviews")]
public class Review
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int BookingId { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    public int WorkerId { get; set; }

    [Required]
    public int Rating { get; set; }

    [MaxLength(1000)]
    public string? Comment { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(BookingId))]
    public virtual Booking? Booking { get; set; }

    [ForeignKey(nameof(UserId))]
    public virtual AppUser? AppUser { get; set; }

    [ForeignKey(nameof(WorkerId))]
    public virtual Worker? Worker { get; set; }
}

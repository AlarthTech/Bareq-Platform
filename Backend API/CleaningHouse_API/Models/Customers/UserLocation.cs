using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Models.Customers;

[Table("UserLocations")]
public class UserLocation
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    [MaxLength(200)]
    public string LocationName { get; set; } = string.Empty;

    [Required]
    public double Lat { get; set; }

    [Required]
    public double Lng { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserId))]
    public virtual AppUser? AppUser { get; set; }

    public virtual ICollection<Booking>? Bookings { get; set; }
}

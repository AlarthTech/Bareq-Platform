using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Companies;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Models.Common;

[Table("AppUsers")]
public class AppUser
{
    [Key]
    public int Id { get; set; }

    [Required] 
    public string FullName { get; set; } = string.Empty;

    public string? Phone { get; set; }

    [Required] 
    public string Email { get; set; } = string.Empty;

    public string? PasswordHash { get; set; }

    [Required]
    public int UserTypeId { get; set; }

    public int? CityId { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("UserTypeId")]
    public virtual UserType? UserType { get; set; }

    [ForeignKey("CityId")]
    public virtual Admin.City? City { get; set; }

    public virtual ICollection<Company>? OwnedCompanies { get; set; }
    public virtual ICollection<Booking>? Bookings { get; set; }
    public virtual ICollection<Review>? Reviews { get; set; }
    public virtual ICollection<Favorite>? Favorites { get; set; }
    public virtual ICollection<UserLocation>? UserLocations { get; set; }
    public virtual ICollection<Report>? Reports { get; set; }
    public virtual ICollection<Notification>? Notifications { get; set; }
    public virtual Wallet.Wallet? Wallet { get; set; }
    public virtual ICollection<ExternalLogin>? ExternalLogins { get; set; }
}


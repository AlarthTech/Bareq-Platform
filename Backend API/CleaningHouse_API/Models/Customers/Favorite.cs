using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;

namespace CleaningHouse_API.Models.Customers;

[Table("Favorites")]
public class Favorite
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    public int WorkerId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("UserId")]
    public virtual AppUser? AppUser { get; set; }

    [ForeignKey("WorkerId")]
    public virtual Worker? Worker { get; set; }
}


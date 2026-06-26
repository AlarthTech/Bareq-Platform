using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Models.Companies;

[Table("CleaningServices")]
public class CleaningService
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    public virtual ICollection<Booking>? Bookings { get; set; }
}

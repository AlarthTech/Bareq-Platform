using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Admin;

[Table("Cities")]
public class City
{
    [Key]
    public int Id { get; set; }

    [Required] 
    public string Name { get; set; } = string.Empty; 

    public bool IsActive { get; set; } = true;
}


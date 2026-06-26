using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Admin;

[Table("Languages")]
public class Language
{
    [Key]
    public int Id { get; set; }

    [Required] 
    public string Name { get; set; } = string.Empty;
  
    public bool IsActive { get; set; } = true;
}


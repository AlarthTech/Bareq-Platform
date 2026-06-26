using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Common;

[Table("UserTypes")]
public class UserType
{
    [Key]
    public int Id { get; set; }

    [Required] 
    public string Name { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;
  
    // Navigation Properties
    public virtual ICollection<AppUser>? AppUsers { get; set; }
}


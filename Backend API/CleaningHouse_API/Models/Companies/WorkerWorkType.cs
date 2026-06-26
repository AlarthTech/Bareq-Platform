using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleaningHouse_API.Models.Companies;

[Table("WorkerWorkTypes")]
public class WorkerWorkType
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int WorkerId { get; set; }

    [Required]
    public int WorkTypeId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    [ForeignKey("WorkerId")]
    public virtual Worker? Worker { get; set; }

    [ForeignKey("WorkTypeId")]
    public virtual WorkType? WorkType { get; set; }
}


using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Companies;

public class WorkTypeDTO
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CompanyId { get; set; }
    public string? CompanyName { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public bool IsOvernight { get; set; }
    public decimal Price { get; set; }
    public decimal? MonthlyPrice { get; set; }
    public bool IsMonthly { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateWorkTypeDTO
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int CompanyId { get; set; }

    [MaxLength(50)]
    public string? StartTime { get; set; }

    [MaxLength(50)]
    public string? EndTime { get; set; }

    public bool IsOvernight { get; set; } = false;

    public bool IsMonthly { get; set; } = false;

    [Required]
    [Range(0, double.MaxValue, ErrorMessage = "السعر يجب أن يكون أكبر من أو يساوي صفر")]
    public decimal Price { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "السعر الشهري يجب أن يكون أكبر من أو يساوي صفر")]
    public decimal? MonthlyPrice { get; set; }
}

public class UpdateWorkTypeDTO
{
    [MaxLength(200)]
    public string? Name { get; set; }

    [MaxLength(50)]
    public string? StartTime { get; set; }

    [MaxLength(50)]
    public string? EndTime { get; set; }

    public bool? IsOvernight { get; set; }

    public bool? IsMonthly { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "السعر يجب أن يكون أكبر من أو يساوي صفر")]
    public decimal? Price { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "السعر الشهري يجب أن يكون أكبر من أو يساوي صفر")]
    public decimal? MonthlyPrice { get; set; }

    public bool? IsActive { get; set; }
}

public class AssignWorkTypeToWorkerDTO
{
    [Required]
    public int WorkerId { get; set; }

    [Required]
    public int WorkTypeId { get; set; }
}

public class WorkerWorkTypeDTO
{
    public int Id { get; set; }
    public int WorkerId { get; set; }
    public string? WorkerName { get; set; }
    public int WorkTypeId { get; set; }
    public string? WorkTypeName { get; set; }
     
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty; 
    public bool IsOvernight { get; set; } 
    public decimal Price { get; set; }
    public decimal? MonthlyPrice { get; set; }


    public DateTime CreatedAt { get; set; }
}



using System.ComponentModel.DataAnnotations;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.DTOs.Customers;

public class ReportDTO
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string? UserName { get; set; }
    public ReportTargetType TargetType { get; set; }
    public string TargetTypeName { get; set; } = string.Empty;
    public int? WorkerId { get; set; }
    public string? WorkerName { get; set; }
    public int? CompanyId { get; set; }
    public string? CompanyName { get; set; }
    public string Description { get; set; } = string.Empty;
    public ReportStatus Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string? AdminNotes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateReportDTO
{
    [Required(ErrorMessage = "نوع البلاغ مطلوب.")]
    public ReportTargetType TargetType { get; set; }

    public int? WorkerId { get; set; }

    public int? CompanyId { get; set; }

    [Required(ErrorMessage = "وصف البلاغ مطلوب.")]
    [MinLength(10, ErrorMessage = "وصف البلاغ يجب أن يكون 10 أحرف على الأقل.")]
    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;
}

public class UpdateReportStatusDTO
{
    [Required]
    public ReportStatus Status { get; set; }

    [MaxLength(2000)]
    public string? AdminNotes { get; set; }
}

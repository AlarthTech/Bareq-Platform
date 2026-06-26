using System.ComponentModel.DataAnnotations;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.DTOs.Customers;

public class CreateBookingReportRequest
{
    [Required(ErrorMessage = "معرف الحجز مطلوب.")]
    public int BookingId { get; set; }

    [Required(ErrorMessage = "سبب البلاغ مطلوب.")]
    [MaxLength(200, ErrorMessage = "سبب البلاغ يجب ألا يتجاوز 200 حرف.")]
    public string Reason { get; set; } = string.Empty;

    [MaxLength(1000, ErrorMessage = "الوصف يجب ألا يتجاوز 1000 حرف.")]
    public string? Description { get; set; }
}

public class UpdateBookingReportStatusRequest : IValidatableObject
{
    [Required(ErrorMessage = "حالة البلاغ مطلوبة.")]
    public int Status { get; set; }

    [MaxLength(1000, ErrorMessage = "ملاحظات الإدارة يجب ألا تتجاوز 1000 حرف.")]
    public string? AdminResolutionNotes { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!BookingReportStatuses.IsValidAdminUpdateTarget(Status))
        {
            yield return new ValidationResult(
                "حالة البلاغ يجب أن تكون قيد المراجعة أو تم الحل أو مرفوض.",
                [nameof(Status)]);
        }

        if (Status is BookingReportStatuses.Resolved or BookingReportStatuses.Rejected
            && string.IsNullOrWhiteSpace(AdminResolutionNotes))
        {
            yield return new ValidationResult(
                "ملاحظات الإدارة مطلوبة عند حل البلاغ أو رفضه.",
                [nameof(AdminResolutionNotes)]);
        }
    }
}

public class BookingReportResponse
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public int CompanyId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public int? WorkerId { get; set; }
    public string? WorkerName { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Status { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string? AdminResolutionNotes { get; set; }
    public int? ResolvedByAdminId { get; set; }
    public string? ResolvedByAdminName { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int BookingStatus { get; set; }
    public string BookingStatusName { get; set; } = string.Empty;
}

public class BookingReportFilterParams
{
    public int? Status { get; set; }
    public int? BookingId { get; set; }
    public int? CustomerId { get; set; }
    public int? CompanyId { get; set; }
    public int? WorkerId { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Customers;

public class PaymentDTO
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string? TransactionId { get; set; }
    public decimal Amount { get; set; }
    public int PaymentStatus { get; set; } // 0 = معلق / 1 = مدفوع / 2 = فشل
    public DateTime? PaidAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreatePaymentDTO
{
    [Required]
    public int BookingId { get; set; }

    [Required]
    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? TransactionId { get; set; }

    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Amount { get; set; }

    [Required]
    [Range(0, 2)]
    public int PaymentStatus { get; set; } // 0 = معلق / 1 = مدفوع / 2 = فشل
}

public class UpdatePaymentDTO
{
    [MaxLength(50)]
    public string? PaymentMethod { get; set; }

    [MaxLength(200)]
    public string? TransactionId { get; set; }

    [Range(0.01, double.MaxValue)]
    public decimal? Amount { get; set; }

    [Range(0, 2)]
    public int? PaymentStatus { get; set; }

    public DateTime? PaidAt { get; set; }
}




















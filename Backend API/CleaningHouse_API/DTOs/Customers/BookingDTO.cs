using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Customers;

public class BookingDTO
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string? UserName { get; set; }
    public int CompanyId { get; set; }
    public string? CompanyName { get; set; }
    public int WorkerId { get; set; }
    public string? WorkerName { get; set; }
    public int WorkTypeId { get; set; }
    public string? WorkTypeName { get; set; }
    public DateTime BookingDate { get; set; }
    public string StartDate { get; set; } = string.Empty;
    public string EndDate { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int? UserLocationId { get; set; }
    public string? LocationName { get; set; }
    public double? Lat { get; set; }
    public double? Lng { get; set; }
    public int Status { get; set; }
    public string? RejectionReason { get; set; }
    public decimal ServicePrice { get; set; }
    public decimal PlatformFeeAmount { get; set; }
    public decimal TotalPrice { get; set; }
    public bool IsMonthlyPricing { get; set; }
    public bool IsWorkerArrivalConfirmed { get; set; }
    public DateTime? WorkerArrivalConfirmedAt { get; set; }
    public bool WalletAmountReserved { get; set; }
    public bool WalletAmountCaptured { get; set; }
    public DateTime? WalletCapturedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateBookingDTO
{
    [Required]
    public int CompanyId { get; set; }

    [Required]
    public int WorkerId { get; set; }

    [Required]
    public int WorkTypeId { get; set; }

    [Required]
    public DateTime BookingDate { get; set; }

    [Required]
    [MaxLength(50)]
    public string StartDate { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string EndDate { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Address { get; set; }

    public int? UserLocationId { get; set; }

    public bool IsMonthly { get; set; }

    /// <summary>Cash, ElectronicPayment, Wallet, or null/empty for unpaid booking flow.</summary>
    [MaxLength(50)]
    public string? PaymentMethod { get; set; }
}

public class UpdateBookingDTO
{
    public int? UserId { get; set; }
    public int? CompanyId { get; set; }
    public int? WorkerId { get; set; }
    public int? WorkTypeId { get; set; }
    public DateTime? BookingDate { get; set; }

    [MaxLength(50)]
    public string? StartDate { get; set; }

    [MaxLength(50)]
    public string? EndDate { get; set; }

    [MaxLength(500)]
    public string? Address { get; set; }

    public int? UserLocationId { get; set; }
}

public class UpdateBookingStatusDTO
{
    [Range(0, 5)]
    public int Status { get; set; }

    [MaxLength(2000)]
    public string? RejectionReason { get; set; }
}
















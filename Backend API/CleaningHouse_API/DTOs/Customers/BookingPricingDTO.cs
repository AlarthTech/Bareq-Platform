using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Customers;

public class BookingPricePreviewDTO
{
    public decimal ServicePrice { get; set; }
    public decimal PlatformFeeAmount { get; set; }
    public decimal TotalPrice { get; set; }
}

public class BookingPricingRequestDTO
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

    public bool IsMonthly { get; set; }
}

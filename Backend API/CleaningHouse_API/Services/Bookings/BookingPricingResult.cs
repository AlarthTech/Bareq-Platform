namespace CleaningHouse_API.Services.Bookings;

public class BookingPricingResult
{
    public decimal ServicePrice { get; init; }
    public decimal PlatformFeeAmount { get; init; }
    public decimal TotalPrice { get; init; }
}

public class BookingPricingValidationException : Exception
{
    public BookingPricingValidationException(string message) : base(message) { }
}

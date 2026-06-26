using CleaningHouse_API.DTOs.Customers;

namespace CleaningHouse_API.Services.Bookings;

public interface IBookingPricingService
{
    Task<BookingPricingResult> CalculateAsync(BookingPricingRequestDTO request, CancellationToken cancellationToken = default);
}

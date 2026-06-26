using CleaningHouse_API.Authentication;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Services.Bookings;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Customers;

[ApiController]
[Route("api/v1/bookings")]
[Authorize(Roles = AppRoles.Customer)]
public class BookingsV1Controller : ControllerBase
{
    private readonly IBookingPricingService _bookingPricingService;

    public BookingsV1Controller(IBookingPricingService bookingPricingService)
    {
        _bookingPricingService = bookingPricingService;
    }

    [HttpPost("price-preview")]
    [ProducesResponseType(typeof(BookingPricePreviewDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<BookingPricePreviewDTO>> PricePreview(
        [FromBody] BookingPricingRequestDTO request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var pricing = await _bookingPricingService.CalculateAsync(request, cancellationToken);
            return Ok(new BookingPricePreviewDTO
            {
                ServicePrice = pricing.ServicePrice,
                PlatformFeeAmount = pricing.PlatformFeeAmount,
                TotalPrice = pricing.TotalPrice
            });
        }
        catch (BookingPricingValidationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

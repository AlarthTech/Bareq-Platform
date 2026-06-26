using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Services.BookingReports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Customers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingReportsController : ControllerBase
{
    private readonly IBookingReportService _bookingReportService;

    public BookingReportsController(IBookingReportService bookingReportService)
    {
        _bookingReportService = bookingReportService;
    }

    /// <summary>Customer — report a problem with a booking.</summary>
    [HttpPost]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(BookingReportResponse), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<BookingReportResponse>> CreateReport(
        [FromBody] CreateBookingReportRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var customerId = User.GetUserId();
        if (customerId is null)
            return Unauthorized();

        var (result, error, statusCode) = await _bookingReportService.CreateReportAsync(
            customerId.Value, request, cancellationToken);

        if (error != null)
            return StatusCode(statusCode ?? 400, new { message = error });

        return StatusCode(StatusCodes.Status201Created, result);
    }

    /// <summary>Customer — paginated list of own booking reports.</summary>
    [HttpGet("MyReports")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(PagedResult<BookingReportResponse>), 200)]
    public async Task<ActionResult<PagedResult<BookingReportResponse>>> GetMyReports(
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var customerId = User.GetUserId();
        if (customerId is null)
            return Unauthorized();

        var result = await _bookingReportService.GetMyReportsAsync(customerId.Value, pagination, cancellationToken);
        return Ok(result);
    }

    /// <summary>Customer — reports for a specific owned booking.</summary>
    [HttpGet("Booking/{bookingId:int}")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(PagedResult<BookingReportResponse>), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<PagedResult<BookingReportResponse>>> GetReportsByBooking(
        int bookingId,
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var customerId = User.GetUserId();
        if (customerId is null)
            return Unauthorized();

        var (result, error, statusCode) = await _bookingReportService.GetReportsByBookingAsync(
            customerId.Value, bookingId, pagination, cancellationToken);

        if (error != null)
            return StatusCode(statusCode ?? 400, new { message = error });

        return Ok(result);
    }

    /// <summary>Admin — all booking reports; Company — reports for owned company bookings.</summary>
    [HttpGet]
    [Authorize(Roles = $"{AppRoles.Admin},{AppRoles.Company}")]
    [ProducesResponseType(typeof(PagedResult<BookingReportResponse>), 200)]
    [ProducesResponseType(403)]
    public async Task<ActionResult<PagedResult<BookingReportResponse>>> GetAllReports(
        [FromQuery] BookingReportFilterParams filters,
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        if (User.IsAdmin())
        {
            var adminResult = await _bookingReportService.GetAllReportsAsync(filters, pagination, cancellationToken);
            return Ok(adminResult);
        }

        var (result, error, statusCode) = await _bookingReportService.GetCompanyReportsAsync(
            userId.Value, filters, pagination, cancellationToken);

        if (error != null)
            return StatusCode(statusCode ?? 400, new { message = error });

        return Ok(result);
    }

    /// <summary>Admin or owning company — booking report details.</summary>
    [HttpGet("{id:int}")]
    [Authorize(Roles = $"{AppRoles.Admin},{AppRoles.Company}")]
    [ProducesResponseType(typeof(BookingReportResponse), 200)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<BookingReportResponse>> GetReportById(int id, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var (result, error, statusCode) = await _bookingReportService.GetReportByIdForUserAsync(
            id, userId.Value, User.IsAdmin(), cancellationToken);

        if (error != null)
            return StatusCode(statusCode ?? 400, new { message = error });

        return Ok(result);
    }

    /// <summary>Admin or owning company — update report status (InReview, Resolved, or Rejected).</summary>
    [HttpPatch("{id:int}/Status")]
    [Authorize(Roles = $"{AppRoles.Admin},{AppRoles.Company}")]
    [ProducesResponseType(typeof(BookingReportResponse), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<BookingReportResponse>> UpdateReportStatus(
        int id,
        [FromBody] UpdateBookingReportStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var (result, error, statusCode) = await _bookingReportService.UpdateReportStatusAsync(
            id, userId.Value, request, User.IsAdmin(), cancellationToken);

        if (error != null)
            return StatusCode(statusCode ?? 400, new { message = error });

        return Ok(result);
    }
}

using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Controllers.Customers;

[ApiController]
[Route("api/[controller]")]
public class ReviewsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public ReviewsController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    [HttpGet("GetReviews")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<ReviewDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ReviewDTO>>> GetReviews([FromQuery] PaginationParams pagination)
    {
        var query = BuildReviewQuery();
        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<ReviewDTO>.Create(
            _mapper.Map<List<ReviewDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetReviewById/{id}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ReviewDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ReviewDTO>> GetReview(int id)
    {
        var review = await BuildReviewQuery().FirstOrDefaultAsync(r => r.Id == id);
        if (review == null)
            return NotFound();

        return Ok(_mapper.Map<ReviewDTO>(review));
    }

    [HttpGet("Worker/{workerId}")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(PagedResult<ReviewDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ReviewDTO>>> GetReviewsByWorker(
        int workerId,
        [FromQuery] PaginationParams pagination)
    {
        var query = BuildReviewQuery()
            .Where(r => r.WorkerId == workerId);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<ReviewDTO>.Create(
            _mapper.Map<List<ReviewDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("Worker/{workerId}/Summary")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(RatingSummaryDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RatingSummaryDTO>> GetWorkerRatingSummary(int workerId)
    {
        var workerExists = await _context.Workers.AsNoTracking()
            .AnyAsync(w => w.Id == workerId && w.IsActive);
        if (!workerExists)
            return NotFound();

        var summary = await _context.Reviews.AsNoTracking()
            .Where(r => r.WorkerId == workerId)
            .GroupBy(_ => 1)
            .Select(g => new RatingSummaryDTO
            {
                AverageRating = g.Average(r => r.Rating),
                TotalReviews = g.Count()
            })
            .FirstOrDefaultAsync();

        return Ok(summary ?? new RatingSummaryDTO());
    }

    [HttpGet("Company/{companyId}/Summary")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(CompanyRatingSummaryDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CompanyRatingSummaryDTO>> GetCompanyRatingSummary(int companyId)
    {
        var company = await _context.Companies.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == companyId && c.IsVerified && c.IsActive);
        if (company == null)
            return NotFound();

        var workerAverages = await _context.Reviews.AsNoTracking()
            .Where(r => r.Worker!.CompanyId == companyId && r.Worker.IsActive)
            .GroupBy(r => r.WorkerId)
            .Select(g => g.Average(r => r.Rating))
            .ToListAsync();

        var totalReviews = await _context.Reviews.AsNoTracking()
            .CountAsync(r => r.Worker!.CompanyId == companyId && r.Worker.IsActive);

        var totalActiveWorkers = await _context.Workers.AsNoTracking()
            .CountAsync(w => w.CompanyId == companyId && w.IsActive);

        return Ok(new CompanyRatingSummaryDTO
        {
            CompanyId = companyId,
            AverageRating = workerAverages.Count > 0 ? workerAverages.Average() : 0,
            TotalReviews = totalReviews,
            RatedWorkersCount = workerAverages.Count,
            TotalActiveWorkers = totalActiveWorkers
        });
    }

    [HttpGet("Company/{companyId}/WorkerSummaries")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(IEnumerable<WorkerRatingSummaryDTO>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<WorkerRatingSummaryDTO>>> GetCompanyWorkerRatingSummaries(int companyId)
    {
        var companyExists = await _context.Companies.AsNoTracking()
            .AnyAsync(c => c.Id == companyId);
        if (!companyExists)
            return NotFound();

        var summaries = await _context.Reviews.AsNoTracking()
            .Where(r => r.Worker!.CompanyId == companyId && r.Worker.IsActive)
            .GroupBy(r => r.WorkerId)
            .Select(g => new WorkerRatingSummaryDTO
            {
                WorkerId = g.Key,
                AverageRating = g.Average(r => r.Rating),
                TotalReviews = g.Count()
            })
            .OrderByDescending(s => s.AverageRating)
            .ToListAsync();

        return Ok(summaries);
    }

    [HttpGet("Booking/{bookingId}")]
    [Authorize]
    [ProducesResponseType(typeof(PagedResult<ReviewDTO>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PagedResult<ReviewDTO>>> GetReviewsByBooking(
        int bookingId,
        [FromQuery] PaginationParams pagination)
    {
        var booking = await _context.Bookings.AsNoTracking().FirstOrDefaultAsync(b => b.Id == bookingId);
        if (booking == null)
            return NotFound();

        if (!await CanAccessBookingAsync(booking))
            return Forbid();

        var query = BuildReviewQuery()
            .Where(r => r.BookingId == bookingId);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<ReviewDTO>.Create(
            _mapper.Map<List<ReviewDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpPost("CreateReview")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(ReviewDTO), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ReviewDTO>> PostReview(CreateReviewDTO createReviewDTO)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var booking = await _context.Bookings.FindAsync(createReviewDTO.BookingId);
        if (booking == null)
            return BadRequest("الحجز غير موجود");

        if (booking.UserId != userId)
            return Forbid();

        if (booking.WorkerId != createReviewDTO.WorkerId)
            return BadRequest("العاملة لا تطابق الحجز");

        if (booking.Status != BookingStatuses.Completed)
            return BadRequest("لا يمكن التقييم إلا بعد إكمال الحجز");

        var worker = await _context.Workers.FindAsync(createReviewDTO.WorkerId);
        if (worker == null)
            return BadRequest("العاملة غير موجودة");

        if (await _context.Reviews.AnyAsync(r => r.BookingId == createReviewDTO.BookingId))
            return BadRequest("تم التقييم على هذا الحجز مسبقاً");

        var review = new Review
        {
            BookingId = createReviewDTO.BookingId,
            UserId = userId.Value,
            WorkerId = createReviewDTO.WorkerId,
            Rating = createReviewDTO.Rating,
            Comment = createReviewDTO.Comment?.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        await _context.Entry(review).Reference(r => r.AppUser).LoadAsync();
        await _context.Entry(review).Reference(r => r.Worker).LoadAsync();

        var reviewDto = _mapper.Map<ReviewDTO>(review);
        return CreatedAtAction(nameof(GetReview), new { id = review.Id }, reviewDto);
    }

    [HttpPatch("UpdateReview/{id}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateReview(int id, UpdateReviewDTO updateReviewDTO)
    {
        var review = await _context.Reviews.FindAsync(id);
        if (review == null)
            return NotFound();

        if (!CanAccessReview(review))
            return Forbid();

        _mapper.Map(updateReviewDTO, review);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Reviews.AnyAsync(r => r.Id == id))
                return NotFound();
            throw;
        }

        return NoContent();
    }

    [HttpDelete("DeleteReview/{id}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteReview(int id)
    {
        var review = await _context.Reviews.FindAsync(id);
        if (review == null)
            return NotFound();

        if (!CanAccessReview(review))
            return Forbid();

        _context.Reviews.Remove(review);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private IQueryable<Review> BuildReviewQuery() =>
        _context.Reviews.AsNoTracking()
            .Include(r => r.AppUser)
            .Include(r => r.Worker)
            .OrderByDescending(r => r.CreatedAt);

    private async Task<bool> CanAccessBookingAsync(Booking booking)
    {
        if (User.IsAdmin())
            return true;

        var userId = User.GetUserId();
        if (!userId.HasValue)
            return false;

        if (booking.UserId == userId)
            return true;

        return await CompanyAccess.UserOwnsCompanyAsync(_context, userId.Value, booking.CompanyId);
    }

    private bool CanAccessReview(Review review)
    {
        if (User.IsAdmin())
            return true;

        var userId = User.GetUserId();
        return userId.HasValue && review.UserId == userId;
    }
}

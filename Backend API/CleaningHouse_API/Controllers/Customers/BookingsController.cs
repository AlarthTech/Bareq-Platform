using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Models.Wallet;
using CleaningHouse_API.Services;
using CleaningHouse_API.Services.Bookings;
using CleaningHouse_API.Services.Notifications;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace CleaningHouse_API.Controllers.Customers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IBookingConflictService _bookingConflictService;
    private readonly IBookingPricingService _bookingPricingService;
    private readonly IBookingWalletService _bookingWalletService;
    private readonly INotificationService _notificationService;

    public BookingsController(
        ApplicationDbContext context,
        IBookingConflictService bookingConflictService,
        IBookingPricingService bookingPricingService,
        IBookingWalletService bookingWalletService,
        INotificationService notificationService)
    {
        _context = context;
        _bookingConflictService = bookingConflictService;
        _bookingPricingService = bookingPricingService;
        _bookingWalletService = bookingWalletService;
        _notificationService = notificationService;
    }

    /// <summary>Admin only — all bookings (paginated).</summary>
    [HttpGet("GetBookings")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<BookingDTO>), 200)]
    public async Task<ActionResult<PagedResult<BookingDTO>>> GetBookings([FromQuery] PaginationParams pagination)
    {
        var query = _context.Bookings.AsNoTracking().ProjectToDto().OrderByDescending(b => b.CreatedAt);
        return Ok(await query.ToPagedResultAsync(pagination));
    }

    [HttpGet("GetBookingById/{id}")]
    [ProducesResponseType(typeof(BookingDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<BookingDTO>> GetBooking(int id)
    {
        var booking = await _context.Bookings.AsNoTracking().ProjectToDto()
            .FirstOrDefaultAsync(b => b.Id == id);

        if (booking == null)
            return NotFound();

        if (!await CanViewBookingAsync(id, booking.UserId, booking.CompanyId))
            return Forbid();

        return Ok(booking);
    }

    [HttpGet("User/{userId}")]
    [ProducesResponseType(typeof(PagedResult<BookingDTO>), 200)]
    public async Task<ActionResult<PagedResult<BookingDTO>>> GetBookingsByUser(
        int userId,
        [FromQuery] PaginationParams pagination)
    {
        if (!User.IsAdmin() && User.GetUserId() != userId)
            return Forbid();

        var query = _context.Bookings.AsNoTracking()
            .Where(b => b.UserId == userId)
            .ProjectToDto()
            .OrderByDescending(b => b.CreatedAt);

        return Ok(await query.ToPagedResultAsync(pagination));
    }

    [HttpGet("Company/{companyId}")]
    [ProducesResponseType(typeof(PagedResult<BookingDTO>), 200)]
    public async Task<ActionResult<PagedResult<BookingDTO>>> GetBookingsByCompany(
        int companyId,
        [FromQuery] PaginationParams pagination)
    {
        if (!User.IsAdmin())
        {
            var uid = User.GetUserId();
            if (uid is null || !await CompanyAccess.UserOwnsCompanyAsync(_context, uid.Value, companyId))
                return Forbid();
        }

        var query = _context.Bookings.AsNoTracking()
            .Where(b => b.CompanyId == companyId)
            .ProjectToDto()
            .OrderByDescending(b => b.CreatedAt);

        return Ok(await query.ToPagedResultAsync(pagination));
    }

    [HttpPost("CreateBooking")]
    [Authorize(Roles = AppRoles.Customer)]
    [EnableRateLimiting("booking-create")]
    [ProducesResponseType(typeof(BookingDTO), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(409)]
    public async Task<ActionResult<BookingDTO>> PostBooking([FromBody] CreateBookingDTO createBookingDTO)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var appUser = await _context.AppUsers.AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId.Value && u.IsActive);
        if (appUser == null)
            return BadRequest("المستخدم غير موجود");

        var company = await _context.Companies.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == createBookingDTO.CompanyId);
        if (company == null)
            return BadRequest("الشركة غير موجودة");

        var worker = await _context.Workers.FirstOrDefaultAsync(w => w.Id == createBookingDTO.WorkerId);
        if (worker == null)
            return BadRequest("العاملة غير موجودة");

        if (worker.CompanyId != createBookingDTO.CompanyId)
            return BadRequest("العاملة لا تنتمي إلى هذه الشركة");

        if (!worker.IsAvailable)
            return BadRequest("العاملة غير متاحة للحجز");

        var workType = await _context.WorkTypes.AsNoTracking()
            .FirstOrDefaultAsync(wt => wt.Id == createBookingDTO.WorkTypeId);
        if (workType == null)
            return BadRequest("نوع العمل غير موجود");

        var addressError = await ApplyBookingLocationAsync(createBookingDTO, userId.Value);
        if (addressError != null)
            return BadRequest(addressError);

        BookingPricingResult pricing;
        try
        {
            pricing = await _bookingPricingService.CalculateAsync(
                new BookingPricingRequestDTO
                {
                    CompanyId = createBookingDTO.CompanyId,
                    WorkerId = createBookingDTO.WorkerId,
                    WorkTypeId = createBookingDTO.WorkTypeId,
                    BookingDate = createBookingDTO.BookingDate,
                    StartDate = createBookingDTO.StartDate,
                    EndDate = createBookingDTO.EndDate,
                    IsMonthly = createBookingDTO.IsMonthly
                },
                HttpContext.RequestAborted);
        }
        catch (BookingPricingValidationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

        var useWallet = string.Equals(
            createBookingDTO.PaymentMethod,
            WalletPaymentMethods.Wallet,
            StringComparison.OrdinalIgnoreCase);

        var cancellationToken = HttpContext.RequestAborted;
        var strategy = _context.Database.CreateExecutionStrategy();
        var outcome = await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);
            try
            {
                var conflict = await _bookingConflictService.CheckCreateBookingConflictAsync(
                    createBookingDTO.WorkerId,
                    userId.Value,
                    createBookingDTO.BookingDate,
                    createBookingDTO.StartDate,
                    createBookingDTO.EndDate,
                    cancellationToken: cancellationToken);

                if (conflict.HasConflict)
                {
                    await transaction.RollbackAsync(cancellationToken);
                    return PostBookingOutcome.Conflict(conflict.Detail ?? "العاملة محجوزة بالفعل في هذا التوقيت.");
                }

                var booking = new Booking
                {
                    UserId = userId.Value,
                    CompanyId = createBookingDTO.CompanyId,
                    WorkerId = createBookingDTO.WorkerId,
                    WorkTypeId = createBookingDTO.WorkTypeId,
                    BookingDate = createBookingDTO.BookingDate,
                    StartDate = createBookingDTO.StartDate,
                    EndDate = createBookingDTO.EndDate,
                    Address = createBookingDTO.Address!.Trim(),
                    UserLocationId = createBookingDTO.UserLocationId,
                    Status = BookingStatuses.Pending,
                    ServicePrice = pricing.ServicePrice,
                    PlatformFeeAmount = pricing.PlatformFeeAmount,
                    TotalPrice = pricing.TotalPrice,
                    IsMonthlyPricing = createBookingDTO.IsMonthly,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Bookings.Add(booking);
                await _context.SaveChangesAsync(cancellationToken);

                if (useWallet)
                {
                    try
                    {
                        await _bookingWalletService.ReserveBookingWalletPaymentAsync(
                            userId.Value,
                            booking.Id,
                            pricing.TotalPrice,
                            cancellationToken);
                    }
                    catch (InsufficientWalletBalanceException ex)
                    {
                        await transaction.RollbackAsync(cancellationToken);
                        return PostBookingOutcome.BadRequest(new InsufficientWalletBalanceDTO
                        {
                            WalletBalance = ex.WalletBalance,
                            RequiredAmount = ex.RequiredAmount
                        });
                    }
                    catch (WalletPaymentException ex)
                    {
                        await transaction.RollbackAsync(cancellationToken);
                        return PostBookingOutcome.BadRequest(new { message = ex.Message });
                    }
                }

                await transaction.CommitAsync(cancellationToken);
                return PostBookingOutcome.Created(booking.Id);
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        });

        if (outcome.ErrorResponse != null)
            return outcome.ErrorResponse;

        if (outcome.BookingId is null)
            return BadRequest("فشل في إنشاء الحجز");

        await _notificationService.NotifyBookingCreatedAsync(outcome.BookingId.Value, cancellationToken);

        var savedBooking = await _context.Bookings.AsNoTracking().ProjectToDto()
            .FirstOrDefaultAsync(b => b.Id == outcome.BookingId.Value, cancellationToken);

        if (savedBooking == null)
            return BadRequest("فشل في إنشاء الحجز");

        return CreatedAtAction(nameof(GetBooking), new { id = outcome.BookingId.Value }, savedBooking);
    }

    /// <summary>
    /// Customer confirms the worker has arrived. For wallet bookings, captures the reserved amount.
    /// </summary>
    [HttpPatch("{id}/ConfirmArrival")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(BookingDTO), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(401)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<BookingDTO>> ConfirmArrival(int id, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        try
        {
            var result = await _bookingWalletService.ConfirmWorkerArrivalAsync(
                userId.Value,
                id,
                cancellationToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("UpdateBooking/{id}")]
    public async Task<IActionResult> UpdateBooking(int id, UpdateBookingDTO updateBookingDTO)
    {
        var booking = await _context.Bookings.FindAsync(id);
        if (booking == null)
            return NotFound();

        if (!await CanModifyBookingAsync(booking))
            return Forbid();

        if (updateBookingDTO.UserId.HasValue && !User.IsAdmin())
            return Forbid();

        if (updateBookingDTO.UserId.HasValue)
        {
            var appUser = await _context.AppUsers.FindAsync(updateBookingDTO.UserId.Value);
            if (appUser == null)
                return BadRequest("المستخدم غير موجود");
            booking.UserId = updateBookingDTO.UserId.Value;
        }

        if (updateBookingDTO.CompanyId.HasValue)
        {
            var company = await _context.Companies.FindAsync(updateBookingDTO.CompanyId.Value);
            if (company == null)
                return BadRequest("الشركة غير موجودة");
            booking.CompanyId = updateBookingDTO.CompanyId.Value;
        }

        if (updateBookingDTO.WorkerId.HasValue)
        {
            var worker = await _context.Workers.FindAsync(updateBookingDTO.WorkerId.Value);
            if (worker == null)
                return BadRequest("العاملة غير موجودة");
            booking.WorkerId = updateBookingDTO.WorkerId.Value;
        }

        if (updateBookingDTO.WorkTypeId.HasValue)
        {
            var workType = await _context.WorkTypes.FindAsync(updateBookingDTO.WorkTypeId.Value);
            if (workType == null)
                return BadRequest("نوع العمل غير موجود");
            booking.WorkTypeId = updateBookingDTO.WorkTypeId.Value;
        }

        if (updateBookingDTO.BookingDate.HasValue)
            booking.BookingDate = updateBookingDTO.BookingDate.Value;

        if (!string.IsNullOrWhiteSpace(updateBookingDTO.StartDate))
            booking.StartDate = updateBookingDTO.StartDate;

        if (!string.IsNullOrWhiteSpace(updateBookingDTO.EndDate))
            booking.EndDate = updateBookingDTO.EndDate;

        if (updateBookingDTO.UserLocationId.HasValue)
        {
            var uid = User.GetUserId() ?? booking.UserId;
            var patchDto = new CreateBookingDTO
            {
                UserLocationId = updateBookingDTO.UserLocationId,
                Address = updateBookingDTO.Address
            };
            var locationError = await ApplyBookingLocationAsync(patchDto, uid);
            if (locationError != null)
                return BadRequest(locationError);
            booking.UserLocationId = updateBookingDTO.UserLocationId;
            booking.Address = patchDto.Address!.Trim();
        }
        else if (!string.IsNullOrWhiteSpace(updateBookingDTO.Address))
        {
            booking.Address = updateBookingDTO.Address.Trim();
            booking.UserLocationId = null;
        }

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("UpdateStatusBooking/{id}")]
    public async Task<IActionResult> UpdateStatusBooking(int id, [FromBody] UpdateBookingStatusDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (dto.Status < BookingStatuses.Pending || dto.Status > BookingStatuses.Rejected)
            return BadRequest("قيمة الحالة غير صالحة.");

        if (dto.Status == BookingStatuses.Rejected && string.IsNullOrWhiteSpace(dto.RejectionReason))
            return BadRequest("سبب الرفض مطلوب.");

        var booking = await _context.Bookings.FindAsync(id);
        if (booking == null)
            return NotFound();

        if (booking.Status == dto.Status)
            return Ok(new { message = "تم تحديث الحالة بنجاح" });

        if (!User.IsAdmin())
        {
            var uid = User.GetUserId();
            if (uid is null)
                return Unauthorized();

            var isCompany = await CompanyAccess.UserOwnsCompanyAsync(_context, uid.Value, booking.CompanyId);
            var isCustomer = booking.UserId == uid.Value;
            if (!isCompany && !isCustomer)
                return Forbid();

            var error = ValidateStatusTransition(booking, dto, isCompany, isCustomer);
            if (error != null)
                return BadRequest(error);
        }

        return await SaveStatusChangeAsync(booking, dto, HttpContext.RequestAborted);
    }

    [HttpDelete("DeleteBooking/{id}")]
    public async Task<IActionResult> DeleteBooking(int id)
    {
        var booking = await _context.Bookings.FindAsync(id);
        if (booking == null)
            return NotFound();

        if (!User.IsAdmin() && User.GetUserId() != booking.UserId)
            return Forbid();

        _context.Bookings.Remove(booking);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private async Task<string?> ApplyBookingLocationAsync(CreateBookingDTO dto, int userId)
    {
        if (dto.UserLocationId.HasValue)
        {
            var location = await _context.UserLocations.AsNoTracking()
                .FirstOrDefaultAsync(l => l.Id == dto.UserLocationId && l.UserId == userId && l.IsActive);
            if (location == null)
                return "الموقع غير موجود أو لا يخص هذا المستخدم";

            dto.Address = location.LocationName;
            return null;
        }

        if (string.IsNullOrWhiteSpace(dto.Address))
            return "يجب تحديد موقع محفوظ (userLocationId) أو عنوان (address)";

        dto.Address = dto.Address.Trim();
        return null;
    }

    private async Task<bool> CanViewBookingAsync(int bookingId, int bookingUserId, int companyId)
    {
        if (User.IsAdmin())
            return true;
        var uid = User.GetUserId();
        if (uid is null)
            return false;
        if (bookingUserId == uid.Value)
            return true;
        return await CompanyAccess.UserOwnsCompanyAsync(_context, uid.Value, companyId);
    }

    private async Task<bool> CanModifyBookingAsync(Booking booking)
    {
        if (User.IsAdmin())
            return true;
        var uid = User.GetUserId();
        if (uid is null)
            return false;
        if (booking.UserId == uid.Value)
            return true;
        return await CompanyAccess.UserOwnsCompanyAsync(_context, uid.Value, booking.CompanyId);
    }

    private static string? ValidateStatusTransition(
        Booking booking,
        UpdateBookingStatusDTO dto,
        bool isCompany,
        bool isCustomer)
    {
        var current = booking.Status;
        var next = dto.Status;

        if (BookingStatuses.IsTerminal(current))
            return "لا يمكن تعديل حالة الحجز النهائية.";

        switch (next)
        {
            case BookingStatuses.Pending:
                return "لا يمكن إعادة الحجز إلى قيد الانتظار.";
            case BookingStatuses.Approved:
                if (current != BookingStatuses.Pending || !isCompany)
                    return "الموافقة متاحة للشركة من حالة الانتظار فقط.";
                break;
            case BookingStatuses.OnTheWay:
                if (current != BookingStatuses.Approved || !isCompany)
                    return "حالة في الطريق متاحة للشركة بعد الموافقة فقط.";
                break;
            case BookingStatuses.Completed:
                if (current != BookingStatuses.Approved && current != BookingStatuses.OnTheWay)
                    return "إكمال الحجز متاح بعد الموافقة أو في الطريق فقط.";
                if (!isCompany && !isCustomer)
                    return "إكمال الحجز متاح للشركة أو العميل.";
                break;
            case BookingStatuses.Canceled:
                if (current != BookingStatuses.Pending)
                    return "الإلغاء متاح فقط لحجوزات قيد الانتظار.";
                if (!isCompany && !isCustomer)
                    return "الإلغاء متاح للشركة أو العميل.";
                break;
            case BookingStatuses.Rejected:
                if (current != BookingStatuses.Pending || !isCompany)
                    return "الرفض متاح للشركة لحجوزات قيد الانتظار فقط.";
                break;
            default:
                return "قيمة الحالة غير صالحة.";
        }

        return null;
    }

    private static void ApplyStatusChange(Booking booking, UpdateBookingStatusDTO dto)
    {
        booking.Status = dto.Status;
        if (dto.Status == BookingStatuses.Rejected)
            booking.RejectionReason = dto.RejectionReason!.Trim();
        else
            booking.RejectionReason = null;
    }

    private async Task<IActionResult> SaveStatusChangeAsync(
        Booking booking,
        UpdateBookingStatusDTO dto,
        CancellationToken cancellationToken)
    {
        var previousStatus = booking.Status;
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(
                IsolationLevel.Serializable,
                cancellationToken);

            ApplyStatusChange(booking, dto);
            await _context.SaveChangesAsync(cancellationToken);
            await _bookingWalletService.ApplyBookingStatusWalletEffectsAsync(
                booking,
                previousStatus,
                dto.Status,
                cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        });

        await _notificationService.NotifyBookingStatusChangedAsync(
            booking.Id,
            previousStatus,
            dto.Status,
            cancellationToken);

        return Ok(new { message = "تم تحديث الحالة بنجاح" });
    }

    private sealed class PostBookingOutcome
    {
        public ActionResult<BookingDTO>? ErrorResponse { get; init; }
        public int? BookingId { get; init; }

        public static PostBookingOutcome Created(int bookingId) =>
            new() { BookingId = bookingId };

        public static PostBookingOutcome Conflict(string detail) =>
            new()
            {
                ErrorResponse = new ConflictObjectResult(new ProblemDetails
                {
                    Title = "Conflict",
                    Detail = detail,
                    Status = StatusCodes.Status409Conflict
                })
            };

        public static PostBookingOutcome BadRequest(object body) =>
            new() { ErrorResponse = new BadRequestObjectResult(body) };
    }
}

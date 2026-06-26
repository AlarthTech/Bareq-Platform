using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Controllers.Customers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public FavoritesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    [HttpGet("GetFavorites")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<FavoriteDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<FavoriteDTO>>> GetFavorites([FromQuery] PaginationParams pagination)
    {
        var query = BuildFavoriteQuery();
        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<FavoriteDTO>.Create(
            _mapper.Map<List<FavoriteDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetFavoriteById/{id}")]
    [ProducesResponseType(typeof(FavoriteDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FavoriteDTO>> GetFavorite(int id)
    {
        var favorite = await BuildFavoriteQuery().FirstOrDefaultAsync(f => f.Id == id);
        if (favorite == null)
            return NotFound();

        if (!CanAccessFavorite(favorite))
            return Forbid();

        return Ok(_mapper.Map<FavoriteDTO>(favorite));
    }

    [HttpGet("User/{userId}")]
    [ProducesResponseType(typeof(PagedResult<FavoriteDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<FavoriteDTO>>> GetFavoritesByUser(
        int userId,
        [FromQuery] PaginationParams pagination)
    {
        if (!User.IsAdmin() && User.GetUserId() != userId)
            return Forbid();

        var query = BuildFavoriteQuery().Where(f => f.UserId == userId);
        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<FavoriteDTO>.Create(
            _mapper.Map<List<FavoriteDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("Worker/{workerId}")]
    [Authorize(Roles = $"{AppRoles.Admin},{AppRoles.Company}")]
    [ProducesResponseType(typeof(PagedResult<FavoriteDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<FavoriteDTO>>> GetFavoritesByWorker(
        int workerId,
        [FromQuery] PaginationParams pagination)
    {
        if (!User.IsAdmin())
        {
            var uid = User.GetUserId();
            if (uid is null || !await CompanyAccess.UserOwnsWorkerAsync(_context, uid.Value, workerId))
                return Forbid();
        }

        var query = BuildFavoriteQuery().Where(f => f.WorkerId == workerId);
        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<FavoriteDTO>.Create(
            _mapper.Map<List<FavoriteDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("CheckFavorite/{userId}/{workerId}")]
    [ProducesResponseType(typeof(bool), StatusCodes.Status200OK)]
    public async Task<ActionResult<bool>> CheckFavorite(int userId, int workerId)
    {
        if (!User.IsAdmin() && User.GetUserId() != userId)
            return Forbid();

        var exists = await _context.Favorites.AnyAsync(f => f.UserId == userId && f.WorkerId == workerId);
        return Ok(exists);
    }

    [HttpPost("CreateFavorite")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(FavoriteDTO), StatusCodes.Status201Created)]
    public async Task<ActionResult<FavoriteDTO>> CreateFavorite(CreateFavoriteDTO dto)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var workerExists = await _context.Workers.AnyAsync(w => w.Id == dto.WorkerId && w.IsActive);
        if (!workerExists)
            return BadRequest("العاملة غير موجودة");

        if (await _context.Favorites.AnyAsync(f => f.UserId == userId && f.WorkerId == dto.WorkerId))
            return BadRequest("العاملة موجودة في المفضلة مسبقاً");

        var favorite = new Favorite
        {
            UserId = userId.Value,
            WorkerId = dto.WorkerId,
            CreatedAt = DateTime.UtcNow
        };
        _context.Favorites.Add(favorite);
        await _context.SaveChangesAsync();

        await _context.Entry(favorite).Reference(f => f.AppUser).LoadAsync();
        await _context.Entry(favorite).Reference(f => f.Worker).LoadAsync();
        if (favorite.Worker != null)
            await _context.Entry(favorite.Worker).Reference(w => w.Company).LoadAsync();

        return CreatedAtAction(nameof(GetFavorite), new { id = favorite.Id }, _mapper.Map<FavoriteDTO>(favorite));
    }

    [HttpDelete("DeleteFavorite/{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteFavorite(int id)
    {
        var favorite = await _context.Favorites.FindAsync(id);
        if (favorite == null)
            return NotFound();

        if (!CanAccessFavorite(favorite))
            return Forbid();

        _context.Favorites.Remove(favorite);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("DeleteFavoriteByUserAndWorker/{userId}/{workerId}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteFavoriteByUserAndWorker(int userId, int workerId)
    {
        if (!User.IsAdmin() && User.GetUserId() != userId)
            return Forbid();

        var favorite = await _context.Favorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.WorkerId == workerId);
        if (favorite == null)
            return NotFound();

        _context.Favorites.Remove(favorite);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private IQueryable<Favorite> BuildFavoriteQuery() =>
        _context.Favorites.AsNoTracking()
            .Include(f => f.AppUser)
            .Include(f => f.Worker)
                .ThenInclude(w => w!.Company)
            .OrderByDescending(f => f.CreatedAt);

    private bool CanAccessFavorite(Favorite favorite)
    {
        if (User.IsAdmin())
            return true;

        var userId = User.GetUserId();
        return userId.HasValue && favorite.UserId == userId;
    }
}

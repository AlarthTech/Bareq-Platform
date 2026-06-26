using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Companies;
using CleaningHouse_API.Models.Companies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Controllers.Companies;

[ApiController]
[Route("api/[controller]")]
public class CleaningServicesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public CleaningServicesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    [HttpGet("GetCleaningServices")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(PagedResult<CleaningServiceDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CleaningServiceDTO>>> GetCleaningServices([FromQuery] PaginationParams pagination)
    {
        var query = _context.CleaningServices.AsNoTracking().OrderBy(s => s.Name);
        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<CleaningServiceDTO>.Create(
            _mapper.Map<List<CleaningServiceDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetCleaningServiceById/{id}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CleaningServiceDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CleaningServiceDTO>> GetCleaningServiceById(int id)
    {
        var service = await _context.CleaningServices.AsNoTracking().FirstOrDefaultAsync(s => s.Id == id);
        if (service == null)
            return NotFound();

        return Ok(_mapper.Map<CleaningServiceDTO>(service));
    }

    [HttpPost("CreateCleaningService")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(CleaningServiceDTO), StatusCodes.Status201Created)]
    public async Task<ActionResult<CleaningServiceDTO>> CreateCleaningService(CreateCleaningServiceDTO dto)
    {
        var service = _mapper.Map<CleaningService>(dto);
        _context.CleaningServices.Add(service);
        await _context.SaveChangesAsync();

        var result = _mapper.Map<CleaningServiceDTO>(service);
        return CreatedAtAction(nameof(GetCleaningServiceById), new { id = service.Id }, result);
    }

    [HttpPatch("UpdateCleaningService/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateCleaningService(int id, UpdateCleaningServiceDTO dto)
    {
        var service = await _context.CleaningServices.FindAsync(id);
        if (service == null)
            return NotFound();

        _mapper.Map(dto, service);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("DeleteCleaningService/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteCleaningService(int id)
    {
        var service = await _context.CleaningServices.FindAsync(id);
        if (service == null)
            return NotFound();

        _context.CleaningServices.Remove(service);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}

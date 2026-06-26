using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Admin;
using CleaningHouse_API.Models.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/[controller]")]
public class CitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public CitiesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    [HttpGet("GetAllCities")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(PagedResult<CityDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CityDTO>>> GetAllCities([FromQuery] PaginationParams pagination)
    {
        var query = _context.Cities.AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.Name);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<CityDTO>.Create(
            _mapper.Map<List<CityDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetCityById/{id}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CityDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CityDTO>> GetCityById(int id)
    {
        var city = await _context.Cities.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
        if (city == null)
            return NotFound();

        return Ok(_mapper.Map<CityDTO>(city));
    }

    [HttpPost("CreateCity")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(CityDTO), StatusCodes.Status201Created)]
    public async Task<ActionResult<CityDTO>> CreateCity(CreateCityDTO createCityDTO)
    {
        var city = _mapper.Map<City>(createCityDTO);
        _context.Cities.Add(city);
        await _context.SaveChangesAsync();

        var cityDto = _mapper.Map<CityDTO>(city);
        return CreatedAtAction(nameof(GetCityById), new { id = city.Id }, cityDto);
    }

    [HttpPatch("UpdateCity/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCity(int id, UpdateCityDTO updateCityDTO)
    {
        var city = await _context.Cities.FindAsync(id);
        if (city == null)
            return NotFound();

        _mapper.Map(updateCityDTO, city);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Cities.AnyAsync(c => c.Id == id))
                return NotFound();
            throw;
        }

        return NoContent();
    }

    [HttpDelete("DeleteCity/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteCity(int id)
    {
        var city = await _context.Cities.FindAsync(id);
        if (city == null)
            return NotFound();

        city.IsActive = false;
        await _context.SaveChangesAsync();
        return NoContent();
    }
}

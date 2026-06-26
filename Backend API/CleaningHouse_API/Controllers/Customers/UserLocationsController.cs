using AutoMapper;
using CleaningHouse_API.Authentication;
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
public class UserLocationsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public UserLocationsController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    [HttpGet("GetMyLocations")]
    [ProducesResponseType(typeof(IEnumerable<UserLocationDTO>), 200)]
    public async Task<ActionResult<IEnumerable<UserLocationDTO>>> GetMyLocations()
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var locations = await _context.UserLocations
            .Where(l => l.UserId == userId && l.IsActive)
            .OrderByDescending(l => l.CreatedAt)
            .ToListAsync();

        return Ok(_mapper.Map<IEnumerable<UserLocationDTO>>(locations));
    }

    [HttpGet("GetUserLocationById/{id}")]
    [ProducesResponseType(typeof(UserLocationDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<UserLocationDTO>> GetUserLocationById(int id)
    {
        var location = await _context.UserLocations
            .FirstOrDefaultAsync(l => l.Id == id && l.IsActive);

        if (location == null)
            return NotFound();

        if (!User.IsAdmin() && User.GetUserId() != location.UserId)
            return Forbid();

        return Ok(_mapper.Map<UserLocationDTO>(location));
    }

    [HttpPost("CreateUserLocation")]
    [ProducesResponseType(typeof(UserLocationDTO), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<UserLocationDTO>> CreateUserLocation(CreateUserLocationDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var location = _mapper.Map<UserLocation>(dto);
        location.UserId = userId.Value;
        _context.UserLocations.Add(location);
        await _context.SaveChangesAsync();

        var result = _mapper.Map<UserLocationDTO>(location);
        return CreatedAtAction(nameof(GetUserLocationById), new { id = location.Id }, result);
    }

    [HttpPut("UpdateUserLocation/{id}")]
    [ProducesResponseType(typeof(UserLocationDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<UserLocationDTO>> UpdateUserLocation(int id, UpdateUserLocationDTO dto)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var location = await _context.UserLocations
            .FirstOrDefaultAsync(l => l.Id == id && l.IsActive);

        if (location == null)
            return NotFound();

        if (!User.IsAdmin() && location.UserId != userId)
            return Forbid();

        if (!string.IsNullOrWhiteSpace(dto.LocationName))
            location.LocationName = dto.LocationName.Trim();

        if (dto.Lat.HasValue)
            location.Lat = dto.Lat.Value;

        if (dto.Lng.HasValue)
            location.Lng = dto.Lng.Value;

        await _context.SaveChangesAsync();
        return Ok(_mapper.Map<UserLocationDTO>(location));
    }

    [HttpDelete("DeleteUserLocation/{id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> DeleteUserLocation(int id)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var location = await _context.UserLocations
            .FirstOrDefaultAsync(l => l.Id == id && l.IsActive);

        if (location == null)
            return NotFound();

        if (!User.IsAdmin() && location.UserId != userId)
            return Forbid();

        location.IsActive = false;
        await _context.SaveChangesAsync();
        return NoContent();
    }
}

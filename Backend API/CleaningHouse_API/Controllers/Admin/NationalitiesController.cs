using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Admin;
using CleaningHouse_API.DTOs.Admin;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NationalitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public NationalitiesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    // GET: api/Nationalities
    [HttpGet("GetNationalities")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<NationalityDTO>>> GetNationalities()
    {
        var nationalities = await _context.Nationalities
            .Where(n => n.IsActive)
            .ToListAsync();
        return Ok(_mapper.Map<IEnumerable<NationalityDTO>>(nationalities));
    }

    // GET: api/Nationalities/{id}
    [HttpGet("GetNationalityById/{id}")]
    [AllowAnonymous]
    public async Task<ActionResult<NationalityDTO>> GetNationalityById(int id)
    {   
        var nationality = await _context.Nationalities.FindAsync(id);

        if (nationality == null)
        {
            return NotFound();
        }

        return Ok(_mapper.Map<NationalityDTO>(nationality));
    }

    // POST: api/Nationalities
    [HttpPost("CreateNationality")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<NationalityDTO>> CreateNationality(CreateNationalityDTO createNationalityDTO)
    {
        var nationality = _mapper.Map<Nationality>(createNationalityDTO);
        _context.Nationalities.Add(nationality);
        await _context.SaveChangesAsync();

        var nationalityDTO = _mapper.Map<NationalityDTO>(nationality);
        return CreatedAtAction(nameof(GetNationalityById), new { id = nationality.Id }, nationalityDTO);
    }

    // PATCH: api/Nationalities/{id}
    [HttpPatch("UpdateNationality/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> UpdateNationality(int id, UpdateNationalityDTO updateNationalityDTO)
    {
        var nationality = await _context.Nationalities.FindAsync(id);
        if (nationality == null)
        {
            return NotFound();
        }

        _mapper.Map(updateNationalityDTO, nationality);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!NationalityExists(id))
            {
                return NotFound();
            }
            else
            {
                throw;
            }
        }

        return NoContent();
    }

    // // DELETE: api/Nationalities/5
    // [HttpDelete("{id}")]
    // public async Task<IActionResult> DeleteNationality(int id)
    // {
    //     var nationality = await _context.Nationalities.FindAsync(id);
    //     if (nationality == null)
    //     {
    //         return NotFound();
    //     }

    //     _context.Nationalities.Remove(nationality);
    //     await _context.SaveChangesAsync();

    //     return NoContent();
    // }

    private bool NationalityExists(int id)
    {
        return _context.Nationalities.Any(e => e.Id == id);
    }
}


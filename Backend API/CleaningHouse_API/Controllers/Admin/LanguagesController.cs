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
public class LanguagesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public LanguagesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    // GET: api/Languages/GetAllLanguages
    [HttpGet("GetAllLanguages")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<LanguageDTO>>> GetAllLanguages()
    {
        var languages = await _context.Languages
            .Where(l => l.IsActive)
            .ToListAsync();
        return Ok(_mapper.Map<IEnumerable<LanguageDTO>>(languages));
    }

    // GET: api/Languages/{id}
    [HttpGet("GetLanguageById/{id}")]
    [AllowAnonymous]
    public async Task<ActionResult<LanguageDTO>> GetLanguageById(int id)
    {
        var language = await _context.Languages.FindAsync(id);

        if (language == null)
        {
            return NotFound();
        }

        return Ok(_mapper.Map<LanguageDTO>(language));
    }

    // POST: api/Languages
    [HttpPost("CreateLanguage")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<ActionResult<LanguageDTO>> CreateLanguage(CreateLanguageDTO createLanguageDTO)
    {
        var language = _mapper.Map<Language>(createLanguageDTO);
        _context.Languages.Add(language);
        await _context.SaveChangesAsync();

        var languageDTO = _mapper.Map<LanguageDTO>(language);
        return CreatedAtAction(nameof(GetLanguageById), new { id = language.Id }, languageDTO);
    }

    // PATCH: api/Languages/{id}
    [HttpPatch("UpdateLanguage/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    public async Task<IActionResult> UpdateLanguage(int id, UpdateLanguageDTO updateLanguageDTO)
    {
        var language = await _context.Languages.FindAsync(id);
        if (language == null)
        {
            return NotFound();
        }

        _mapper.Map(updateLanguageDTO, language);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!LanguageExists(id))
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

    // DELETE: api/Languages/5
    // [HttpDelete("{id}")]
    // public async Task<IActionResult> DeleteLanguage(int id)
    // {
    //     var language = await _context.Languages.FindAsync(id);
    //     if (language == null)
    //     {
    //         return NotFound();
    //     }

    //     _context.Languages.Remove(language);
    //     await _context.SaveChangesAsync();

    //     return NoContent();
    // }

    private bool LanguageExists(int id)
    {
        return _context.Languages.Any(e => e.Id == id);
    }
}


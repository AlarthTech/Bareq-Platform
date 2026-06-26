using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AutoMapper;
using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.DTOs.Common;

namespace CleaningHouse_API.Controllers.Common;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UserTypesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public UserTypesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    // GET: api/UserTypes
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<UserTypeDTO>>> GetUserTypes()
    {
        var userTypes = await _context.UserTypes.ToListAsync();
        return Ok(_mapper.Map<IEnumerable<UserTypeDTO>>(userTypes));
    }

    // GET: api/UserTypes/5
    // [HttpGet("{id}")]
    // public async Task<ActionResult<UserTypeDTO>> GetUserType(int id)
    // {
    //     var userType = await _context.UserTypes.FindAsync(id);

    //     if (userType == null)
    //     {
    //         return NotFound();
    //     }

    //     return Ok(_mapper.Map<UserTypeDTO>(userType));
    // }

    // // POST: api/UserTypes
    // [HttpPost]
    // [ProducesResponseType(typeof(UserTypeDTO), 201)]
    // [ProducesResponseType(400)]
    // public async Task<ActionResult<UserTypeDTO>> PostUserType(CreateUserTypeDTO createUserTypeDTO)
    // {
    //     var userType = _mapper.Map<UserType>(createUserTypeDTO);
    //     _context.UserTypes.Add(userType);
    //     await _context.SaveChangesAsync();

    //     var userTypeDTO = _mapper.Map<UserTypeDTO>(userType);
    //     return CreatedAtAction(nameof(GetUserType), new { id = userType.Id }, userTypeDTO);
    // }

    // // PUT: api/UserTypes/5
    // [HttpPut("{id}")]
    // [ProducesResponseType(204)]
    // [ProducesResponseType(400)]
    // [ProducesResponseType(404)]
    // public async Task<IActionResult> PutUserType(int id, UpdateUserTypeDTO updateUserTypeDTO)
    // {
    //     var userType = await _context.UserTypes.FindAsync(id);
    //     if (userType == null)
    //     {
    //         return NotFound();
    //     }

    //     _mapper.Map(updateUserTypeDTO, userType);

    //     try
    //     {
    //         await _context.SaveChangesAsync();
    //     }
    //     catch (DbUpdateConcurrencyException)
    //     {
    //         if (!UserTypeExists(id))
    //         {
    //             return NotFound();
    //         }
    //         else
    //         {
    //             throw;
    //         }
    //     }

    //     return NoContent();
    // }

    // // DELETE: api/UserTypes/5
    // [HttpDelete("{id}")]
    // [ProducesResponseType(204)]
    // [ProducesResponseType(404)]
    // public async Task<IActionResult> DeleteUserType(int id)
    // {
    //     var userType = await _context.UserTypes.FindAsync(id);
    //     if (userType == null)
    //     {
    //         return NotFound();
    //     }

    //     _context.UserTypes.Remove(userType);
    //     await _context.SaveChangesAsync();

    //     return NoContent();
    // }

    // private bool UserTypeExists(int id)
    // {
    //     return _context.UserTypes.Any(e => e.Id == id);
    // }
}


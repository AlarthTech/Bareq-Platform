using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Companies;
using CleaningHouse_API.Models.Companies;
using CleaningHouse_API.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Controllers.Companies;

[ApiController]
[Route("api/[controller]")]
public class CompaniesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;
    private readonly IWebHostEnvironment _env;
    private readonly INotificationService _notificationService;

    public CompaniesController(
        ApplicationDbContext context,
        IMapper mapper,
        IWebHostEnvironment env,
        INotificationService notificationService)
    {
        _context = context;
        _mapper = mapper;
        _env = env;
        _notificationService = notificationService;
    }

    [HttpGet("GetAllCompanies")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<CompanyDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CompanyDTO>>> GetCompanies([FromQuery] PaginationParams pagination)
    {
        var query = _context.Companies.AsNoTracking()
            .Include(c => c.OwnerAppUser)
            .Include(c => c.City)
            .OrderByDescending(c => c.CreatedAt);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<CompanyDTO>.Create(
            _mapper.Map<List<CompanyDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetActiveCompanies")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(PagedResult<CompanyDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CompanyDTO>>> GetActiveCompanies([FromQuery] PaginationParams pagination)
    {
        var query = _context.Companies.AsNoTracking()
            .Where(c => c.IsActive)
            .Include(c => c.OwnerAppUser)
            .Include(c => c.City)
            .OrderBy(c => c.Name);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<CompanyDTO>.Create(
            _mapper.Map<List<CompanyDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetisVerifiedCompanies")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(PagedResult<CompanyDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CompanyDTO>>> GetisVerifiedCompanies([FromQuery] PaginationParams pagination)
    {
        var query = _context.Companies.AsNoTracking()
            .Where(c => c.IsVerified && c.IsActive)
            .Include(c => c.OwnerAppUser)
            .Include(c => c.City)
            .OrderBy(c => c.Name);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<CompanyDTO>.Create(
            _mapper.Map<List<CompanyDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetCompanyById/{id}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CompanyDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CompanyDTO>> GetCompanyById(int id)
    {
        var company = await _context.Companies.AsNoTracking()
            .Include(c => c.OwnerAppUser)
            .Include(c => c.City)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (company == null)
            return NotFound();

        return Ok(_mapper.Map<CompanyDTO>(company));
    }

    [HttpGet("GetMyCompanyByIdUser/{idUser}")]
    [Authorize]
    [ProducesResponseType(typeof(IEnumerable<CompanyDTO>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<CompanyDTO>>> GetMyCompanyByIdUser(int idUser)
    {
        if (!User.IsAdmin() && User.GetUserId() != idUser)
            return Forbid();

        var companies = await _context.Companies.AsNoTracking()
            .Where(c => c.OwnerUserId == idUser)
            .Include(c => c.OwnerAppUser)
            .Include(c => c.City)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

        return Ok(_mapper.Map<List<CompanyDTO>>(companies));
    }

    [HttpPost("CreateCompany")]
    [Authorize]
    [ProducesResponseType(typeof(CompanyDTO), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CompanyDTO>> CreateCompany(CreateCompanyDTO createCompanyDTO)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        if (!User.IsAdmin() && createCompanyDTO.OwnerUserId != userId)
            return Forbid();

        if (await _context.Companies.AnyAsync(c => c.Email == createCompanyDTO.Email))
            return BadRequest("البريد الإلكتروني مستخدم بالفعل");

        var company = _mapper.Map<Company>(createCompanyDTO);
        company.IsActive = false;
        company.IsVerified = false;
        company.CreatedAt = DateTime.UtcNow;

        _context.Companies.Add(company);
        await _context.SaveChangesAsync();

        await _notificationService.NotifyNewCompanyPendingApprovalAsync(company.Id);

        await _context.Entry(company).Reference(c => c.OwnerAppUser).LoadAsync();
        await _context.Entry(company).Reference(c => c.City).LoadAsync();

        var companyDto = _mapper.Map<CompanyDTO>(company);
        return CreatedAtAction(nameof(GetCompanyById), new { id = company.Id }, companyDto);
    }

    [HttpPatch("UpdateCompany/{id}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCompany(int id, UpdateCompanyDTO updateCompanyDTO)
    {
        var company = await _context.Companies.FindAsync(id);
        if (company == null)
            return NotFound();

        var userId = User.GetUserId();
        if (!User.IsAdmin() && (userId is null || company.OwnerUserId != userId))
            return Forbid();

        _mapper.Map(updateCompanyDTO, company);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Companies.AnyAsync(c => c.Id == id))
                return NotFound();
            throw;
        }

        return NoContent();
    }

    [HttpDelete("DeleteCompany/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteCompany(int id)
    {
        var company = await _context.Companies.FindAsync(id);
        if (company == null)
            return NotFound();

        _context.Companies.Remove(company);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("UpdateCompanyIsActive/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCompanyIsActive(int id)
    {
        var company = await _context.Companies.FindAsync(id);
        if (company == null)
            return NotFound();

        company.IsActive = !company.IsActive;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("UpdateCompanyisVerified/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCompanyisVerified(int id)
    {
        var company = await _context.Companies.FindAsync(id);
        if (company == null)
            return NotFound();

        company.IsVerified = !company.IsVerified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("UploadCommercialRegister/{id}")]
    [Authorize]
    [ProducesResponseType(typeof(CompanyDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CompanyDTO>> UploadCommercialRegister(int id, IFormFile file)
    {
        return await SaveCommercialRegisterAsync(id, file);
    }

    [HttpPost("UpdateCommercialRegister/{id}")]
    [Authorize]
    [ProducesResponseType(typeof(CompanyDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CompanyDTO>> UpdateCommercialRegister(int id, IFormFile file)
    {
        return await SaveCommercialRegisterAsync(id, file);
    }

    private async Task<ActionResult<CompanyDTO>> SaveCommercialRegisterAsync(int id, IFormFile? file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("الملف مطلوب");

        var company = await _context.Companies
            .Include(c => c.OwnerAppUser)
            .Include(c => c.City)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (company == null)
            return NotFound();

        var userId = User.GetUserId();
        if (!User.IsAdmin() && (userId is null || company.OwnerUserId != userId))
            return Forbid();

        var uploadsDir = Path.Combine(_env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"),
            "uploads", "commercial-registers", id.ToString());
        Directory.CreateDirectory(uploadsDir);

        var extension = Path.GetExtension(file.FileName);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var filePath = Path.Combine(uploadsDir, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        company.CommercialRegisterURL = $"/uploads/commercial-registers/{id}/{fileName}";
        await _context.SaveChangesAsync();

        return Ok(_mapper.Map<CompanyDTO>(company));
    }
}

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
public class WorkersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;
    private readonly IWebHostEnvironment _env;

    public WorkersController(ApplicationDbContext context, IMapper mapper, IWebHostEnvironment env)
    {
        _context = context;
        _mapper = mapper;
        _env = env;
    }

    [HttpGet("GetWorkers")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<WorkerDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<WorkerDTO>>> GetWorkers([FromQuery] PaginationParams pagination)
    {
        var query = _context.Workers.AsNoTracking()
            .Include(w => w.Company)
            .Include(w => w.Nationality)
            .OrderByDescending(w => w.CreatedAt);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<WorkerDTO>.Create(
            _mapper.Map<List<WorkerDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetWorkerById/{id}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(WorkerDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WorkerDTO>> GetWorkerById(int id)
    {
        var worker = await _context.Workers.AsNoTracking()
            .Include(w => w.Company)
            .Include(w => w.Nationality)
            .FirstOrDefaultAsync(w => w.Id == id);

        if (worker == null)
            return NotFound();

        return Ok(_mapper.Map<WorkerDTO>(worker));
    }

    [HttpGet("Company/{companyId}")]
    [Authorize]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(PagedResult<WorkerDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<WorkerDTO>>> GetWorkersByCompany(
        int companyId,
        [FromQuery] PaginationParams pagination)
    {
        if (!User.IsAdmin())
        {
            var uid = User.GetUserId();
            if (uid is null || !await CompanyAccess.UserOwnsCompanyAsync(_context, uid.Value, companyId))
                return Forbid();
        }

        var query = _context.Workers.AsNoTracking()
            .Where(w => w.CompanyId == companyId)
            .Include(w => w.Company)
            .Include(w => w.Nationality)
            .OrderBy(w => w.FullName);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<WorkerDTO>.Create(
            _mapper.Map<List<WorkerDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetActiveWorkers")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(IEnumerable<WorkerDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<WorkerDTO>>> GetActiveWorkers([FromQuery] int? companyId)
    {
        var query = _context.Workers.AsNoTracking()
            .Where(w => w.IsActive)
            .Include(w => w.Company)
            .Include(w => w.Nationality)
            .AsQueryable();

        if (companyId.HasValue)
            query = query.Where(w => w.CompanyId == companyId.Value);

        var workers = await query.OrderBy(w => w.FullName).ToListAsync();
        return Ok(_mapper.Map<List<WorkerDTO>>(workers));
    }

    [HttpPost("CreateWorker")]
    [Authorize]
    [ProducesResponseType(typeof(WorkerDTO), StatusCodes.Status201Created)]
    public async Task<ActionResult<WorkerDTO>> PostWorker(CreateWorkerDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (!await CanManageCompanyAsync(dto.CompanyId))
            return Forbid();

        var worker = _mapper.Map<Worker>(dto);
        worker.IsActive = false;
        worker.CreatedAt = DateTime.UtcNow;
        _context.Workers.Add(worker);
        await _context.SaveChangesAsync();

        await _context.Entry(worker).Reference(w => w.Company).LoadAsync();
        await _context.Entry(worker).Reference(w => w.Nationality).LoadAsync();
        return CreatedAtAction(nameof(GetWorkerById), new { id = worker.Id }, _mapper.Map<WorkerDTO>(worker));
    }

    [HttpPatch("UpdateWorker/{id}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateWorker(int id, UpdateWorkerDTO dto)
    {
        var worker = await _context.Workers.FindAsync(id);
        if (worker == null)
            return NotFound();

        if (!await CanManageCompanyAsync(worker.CompanyId))
            return Forbid();

        _mapper.Map(dto, worker);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("UpdateWorkerIsActive/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateWorkerIsActive(int id)
    {
        var worker = await _context.Workers.FindAsync(id);
        if (worker == null)
            return NotFound();

        worker.IsActive = !worker.IsActive;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("DeleteWorker/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteWorker(int id)
    {
        var worker = await _context.Workers.FindAsync(id);
        if (worker == null)
            return NotFound();

        worker.IsActive = false;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("UploadHealthCertificate/{id}")]
    [Authorize]
    [ProducesResponseType(typeof(WorkerDTO), StatusCodes.Status200OK)]
    public async Task<ActionResult<WorkerDTO>> UploadHealthCertificate(int id, IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("الملف مطلوب");

        var worker = await _context.Workers
            .Include(w => w.Company)
            .Include(w => w.Nationality)
            .FirstOrDefaultAsync(w => w.Id == id);

        if (worker == null)
            return NotFound();

        if (!await CanManageCompanyAsync(worker.CompanyId))
            return Forbid();

        var uploadsDir = Path.Combine(_env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"),
            "uploads", "health-certificates", id.ToString());
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{Guid.NewGuid():N}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadsDir, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        worker.HealthCertificateURL = $"/uploads/health-certificates/{id}/{fileName}";
        await _context.SaveChangesAsync();

        return Ok(_mapper.Map<WorkerDTO>(worker));
    }

    private async Task<bool> CanManageCompanyAsync(int companyId)
    {
        if (User.IsAdmin())
            return true;

        var userId = User.GetUserId();
        return userId.HasValue &&
               await CompanyAccess.UserOwnsCompanyAsync(_context, userId.Value, companyId);
    }
}

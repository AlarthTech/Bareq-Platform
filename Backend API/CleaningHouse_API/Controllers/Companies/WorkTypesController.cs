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
public class WorkTypesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public WorkTypesController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    [HttpGet("GetAllWorkTypes")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(PagedResult<WorkTypeDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<WorkTypeDTO>>> GetWorkTypes([FromQuery] PaginationParams pagination)
    {
        var query = _context.WorkTypes.AsNoTracking()
            .Include(wt => wt.Company)
            .OrderBy(wt => wt.Name);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<WorkTypeDTO>.Create(
            _mapper.Map<List<WorkTypeDTO>>(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    [HttpGet("GetWorkTypesByCompany/{companyId}")]
    [AllowAnonymous]
    [EnableRateLimiting("search")]
    [ProducesResponseType(typeof(IEnumerable<WorkTypeDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<WorkTypeDTO>>> GetWorkTypesByCompany(int companyId)
    {
        var workTypes = await _context.WorkTypes.AsNoTracking()
            .Where(wt => wt.CompanyId == companyId && wt.IsActive)
            .Include(wt => wt.Company)
            .OrderBy(wt => wt.Name)
            .ToListAsync();

        return Ok(_mapper.Map<List<WorkTypeDTO>>(workTypes));
    }

    [HttpGet("GetWorkTypeById/{id}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(WorkTypeDTO), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<WorkTypeDTO>> GetWorkTypeById(int id)
    {
        var workType = await _context.WorkTypes.AsNoTracking()
            .Include(wt => wt.Company)
            .FirstOrDefaultAsync(wt => wt.Id == id);

        if (workType == null)
            return NotFound();

        return Ok(_mapper.Map<WorkTypeDTO>(workType));
    }

    [HttpPost("CreateWorkType")]
    [Authorize]
    [ProducesResponseType(typeof(WorkTypeDTO), StatusCodes.Status201Created)]
    public async Task<ActionResult<WorkTypeDTO>> CreateWorkType(CreateWorkTypeDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var company = await _context.Companies.FindAsync(dto.CompanyId);
        if (company == null)
            return BadRequest("الشركة غير موجودة");

        if (!await CanManageCompanyAsync(company.Id))
            return Forbid();

        if (dto.IsMonthly && dto.MonthlyPrice is null && dto.Price <= 0)
            return BadRequest("السعر الشهري مطلوب للتصنيف الشهري");

        var workType = _mapper.Map<WorkType>(dto);
        workType.CreatedAt = DateTime.UtcNow;
        _context.WorkTypes.Add(workType);
        await _context.SaveChangesAsync();

        await _context.Entry(workType).Reference(w => w.Company).LoadAsync();
        return CreatedAtAction(nameof(GetWorkTypeById), new { id = workType.Id }, _mapper.Map<WorkTypeDTO>(workType));
    }

    [HttpPatch("UpdateWorkType/{id}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateWorkType(int id, UpdateWorkTypeDTO dto)
    {
        var workType = await _context.WorkTypes.FindAsync(id);
        if (workType == null)
            return NotFound();

        if (!await CanManageCompanyAsync(workType.CompanyId))
            return Forbid();

        _mapper.Map(dto, workType);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("DeleteWorkType/{id}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteWorkType(int id)
    {
        var workType = await _context.WorkTypes.FindAsync(id);
        if (workType == null)
            return NotFound();

        if (!await CanManageCompanyAsync(workType.CompanyId))
            return Forbid();

        workType.IsActive = false;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("GetWorkerWorkTypes/{workerId}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(IEnumerable<WorkerWorkTypeDTO>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<WorkerWorkTypeDTO>>> GetWorkerWorkTypes(int workerId)
    {
        var items = await _context.WorkerWorkTypes.AsNoTracking()
            .Where(w => w.WorkerId == workerId)
            .Include(w => w.Worker)
            .Include(w => w.WorkType)
            .OrderBy(w => w.WorkType!.Name)
            .ToListAsync();

        return Ok(_mapper.Map<List<WorkerWorkTypeDTO>>(items));
    }

    [HttpPost("AssignWorkTypeToWorker")]
    [Authorize]
    [ProducesResponseType(typeof(WorkerWorkTypeDTO), StatusCodes.Status200OK)]
    public async Task<ActionResult<WorkerWorkTypeDTO>> AssignWorkTypeToWorker(AssignWorkTypeToWorkerDTO dto)
    {
        var worker = await _context.Workers.FindAsync(dto.WorkerId);
        var workType = await _context.WorkTypes.FindAsync(dto.WorkTypeId);
        if (worker == null || workType == null)
            return BadRequest("العاملة أو نوع العمل غير موجود");

        if (worker.CompanyId != workType.CompanyId)
            return BadRequest("نوع العمل لا يتبع نفس شركة العاملة");

        if (!await CanManageCompanyAsync(worker.CompanyId))
            return Forbid();

        if (await _context.WorkerWorkTypes.AnyAsync(w =>
                w.WorkerId == dto.WorkerId && w.WorkTypeId == dto.WorkTypeId))
            return BadRequest("نوع العمل مُعيَّن مسبقاً لهذه العاملة");

        var link = new WorkerWorkType
        {
            WorkerId = dto.WorkerId,
            WorkTypeId = dto.WorkTypeId,
            CreatedAt = DateTime.UtcNow
        };
        _context.WorkerWorkTypes.Add(link);
        await _context.SaveChangesAsync();

        await _context.Entry(link).Reference(w => w.Worker).LoadAsync();
        await _context.Entry(link).Reference(w => w.WorkType).LoadAsync();
        return Ok(_mapper.Map<WorkerWorkTypeDTO>(link));
    }

    [HttpDelete("RemoveWorkTypeFromWorker")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> RemoveWorkTypeFromWorker([FromQuery] int workerId, [FromQuery] int workTypeId)
    {
        var link = await _context.WorkerWorkTypes
            .FirstOrDefaultAsync(w => w.WorkerId == workerId && w.WorkTypeId == workTypeId);
        if (link == null)
            return NotFound();

        var worker = await _context.Workers.FindAsync(workerId);
        if (worker == null || !await CanManageCompanyAsync(worker.CompanyId))
            return Forbid();

        _context.WorkerWorkTypes.Remove(link);
        await _context.SaveChangesAsync();
        return NoContent();
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

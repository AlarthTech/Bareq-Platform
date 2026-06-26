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
public class ReportsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public ReportsController(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    /// <summary>Admin — all reports (paginated).</summary>
    [HttpGet("GetReports")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<ReportDTO>), 200)]
    public async Task<ActionResult<PagedResult<ReportDTO>>> GetReports([FromQuery] PaginationParams pagination)
    {
        var query = BuildReportQuery().OrderByDescending(r => r.CreatedAt);
        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<ReportDTO>.Create(
            MapReports(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    /// <summary>Customer — own reports only (paginated).</summary>
    [HttpGet("GetMyReports")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(PagedResult<ReportDTO>), 200)]
    public async Task<ActionResult<PagedResult<ReportDTO>>> GetMyReports([FromQuery] PaginationParams pagination)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var query = BuildReportQuery()
            .Where(r => r.UserId == userId.Value)
            .OrderByDescending(r => r.CreatedAt);

        var paged = await query.ToPagedResultAsync(pagination);
        return Ok(PagedResult<ReportDTO>.Create(
            MapReports(paged.Items), paged.Page, paged.PageSize, paged.TotalCount));
    }

    /// <summary>Admin or report owner only.</summary>
    [HttpGet("GetReportById/{id}")]
    [ProducesResponseType(typeof(ReportDTO), 200)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<ReportDTO>> GetReportById(int id)
    {
        var report = await BuildReportQuery().FirstOrDefaultAsync(r => r.Id == id);
        if (report == null)
            return NotFound();

        if (!CanAccessReport(report))
            return Forbid();

        return Ok(MapReport(report));
    }

    /// <summary>Customer — report a worker or company.</summary>
    [HttpPost("CreateReport")]
    [Authorize(Roles = AppRoles.Customer)]
    [ProducesResponseType(typeof(ReportDTO), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<ReportDTO>> CreateReport([FromBody] CreateReportDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var validationError = await ValidateCreateReportAsync(dto);
        if (validationError != null)
            return BadRequest(validationError);

        var report = new Report
        {
            UserId = userId.Value,
            TargetType = dto.TargetType,
            WorkerId = dto.TargetType == ReportTargetType.Worker ? dto.WorkerId : null,
            CompanyId = dto.TargetType == ReportTargetType.Company ? dto.CompanyId : null,
            Description = dto.Description.Trim(),
            Status = ReportStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reports.Add(report);
        await _context.SaveChangesAsync();

        var created = await BuildReportQuery().FirstAsync(r => r.Id == report.Id);
        return CreatedAtAction(nameof(GetReportById), new { id = report.Id }, MapReport(created));
    }

    /// <summary>Admin — update status and internal notes.</summary>
    [HttpPatch("UpdateReportStatus/{id}")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(ReportDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<ReportDTO>> UpdateReportStatus(int id, [FromBody] UpdateReportStatusDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var report = await _context.Reports.FindAsync(id);
        if (report == null)
            return NotFound();

        report.Status = dto.Status;
        if (dto.AdminNotes != null)
            report.AdminNotes = dto.AdminNotes.Trim();
        report.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var updated = await BuildReportQuery().FirstAsync(r => r.Id == id);
        return Ok(MapReport(updated));
    }

    /// <summary>Admin or report owner — delete report.</summary>
    [HttpDelete("DeleteReport/{id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(403)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> DeleteReport(int id)
    {
        var report = await _context.Reports.FindAsync(id);
        if (report == null)
            return NotFound();

        if (!CanAccessReport(report))
            return Forbid();

        _context.Reports.Remove(report);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private IQueryable<Report> BuildReportQuery() =>
        _context.Reports.AsNoTracking()
            .Include(r => r.AppUser)
            .Include(r => r.Worker)
            .Include(r => r.Company);

    private bool CanAccessReport(Report report)
    {
        if (User.IsAdmin())
            return true;

        var userId = User.GetUserId();
        return userId.HasValue && report.UserId == userId.Value;
    }

    private async Task<string?> ValidateCreateReportAsync(CreateReportDTO dto)
    {
        return dto.TargetType switch
        {
            ReportTargetType.Worker => await ValidateWorkerReportAsync(dto),
            ReportTargetType.Company => await ValidateCompanyReportAsync(dto),
            _ => "نوع البلاغ غير صالح."
        };
    }

    private async Task<string?> ValidateWorkerReportAsync(CreateReportDTO dto)
    {
        if (!dto.WorkerId.HasValue || dto.WorkerId <= 0)
            return "يجب تحديد العاملة المراد الإبلاغ عنها.";

        if (dto.CompanyId.HasValue)
            return "لا يمكن الإبلاغ عن عاملة وشركة في نفس البلاغ.";

        var workerExists = await _context.Workers.AnyAsync(w => w.Id == dto.WorkerId && w.IsActive);
        if (!workerExists)
            return "العاملة غير موجودة.";

        return null;
    }

    private async Task<string?> ValidateCompanyReportAsync(CreateReportDTO dto)
    {
        if (!dto.CompanyId.HasValue || dto.CompanyId <= 0)
            return "يجب تحديد الشركة المراد الإبلاغ عنها.";

        if (dto.WorkerId.HasValue)
            return "لا يمكن الإبلاغ عن عاملة وشركة في نفس البلاغ.";

        var companyExists = await _context.Companies.AnyAsync(c => c.Id == dto.CompanyId);
        if (!companyExists)
            return "الشركة غير موجودة.";

        return null;
    }

    private List<ReportDTO> MapReports(IEnumerable<Report> reports) =>
        reports.Select(MapReport).ToList();

    private ReportDTO MapReport(Report report)
    {
        var dto = _mapper.Map<ReportDTO>(report);
        dto.TargetTypeName = report.TargetType == ReportTargetType.Worker ? "عاملة" : "شركة";
        dto.StatusName = report.Status switch
        {
            ReportStatus.Pending => "قيد الانتظار",
            ReportStatus.UnderReview => "قيد المراجعة",
            ReportStatus.Resolved => "تم الحل",
            ReportStatus.Dismissed => "مرفوض",
            _ => report.Status.ToString()
        };
        return dto;
    }
}

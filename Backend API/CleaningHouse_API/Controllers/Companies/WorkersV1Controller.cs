using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Companies;
using CleaningHouse_API.Services.Workers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace CleaningHouse_API.Controllers.Companies;

[ApiController]
[Route("api/v1/workers")]
[AllowAnonymous]
[EnableRateLimiting("search")]
public class WorkersV1Controller : ControllerBase
{
    private readonly IWorkerHomeService _workerHomeService;

    public WorkersV1Controller(IWorkerHomeService workerHomeService)
    {
        _workerHomeService = workerHomeService;
    }

    /// <summary>Workers available on the selected calendar day (no active pending/approved/on-the-way booking).</summary>
    [HttpGet("available")]
    [ProducesResponseType(typeof(PagedResult<WorkerCardDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<WorkerCardDto>>> GetAvailableWorkers(
        [FromQuery] DateOnly? date,
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var selectedDate = date ?? WorkerAvailabilityLabels.TodayUtc();
        var result = await _workerHomeService.GetAvailableWorkersAsync(
            selectedDate,
            pagination ?? new PaginationParams(),
            cancellationToken);
        return Ok(result);
    }

    /// <summary>Workers sorted by rating (highest first), with next-available date for home screen.</summary>
    [HttpGet("top-rated")]
    [ProducesResponseType(typeof(PagedResult<WorkerCardDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<WorkerCardDto>>> GetTopRatedWorkers(
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var result = await _workerHomeService.GetTopRatedWorkersAsync(
            pagination ?? new PaginationParams(),
            cancellationToken);
        return Ok(result);
    }
}

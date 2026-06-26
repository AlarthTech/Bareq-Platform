using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Companies;

namespace CleaningHouse_API.Services.Workers;

public interface IWorkerHomeService
{
    Task<PagedResult<WorkerCardDto>> GetAvailableWorkersAsync(
        DateOnly selectedDate,
        PaginationParams pagination,
        CancellationToken cancellationToken = default);

    Task<PagedResult<WorkerCardDto>> GetTopRatedWorkersAsync(
        PaginationParams pagination,
        CancellationToken cancellationToken = default);
}

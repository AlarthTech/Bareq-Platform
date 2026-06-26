using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Core.Pagination;

public static class PaginationExtensions
{
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(
        this IQueryable<T> query,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var (page, pageSize, skip) = pagination.Normalize();
        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query.Skip(skip).Take(pageSize).ToListAsync(cancellationToken);
        return PagedResult<T>.Create(items, page, pageSize, totalCount);
    }
}

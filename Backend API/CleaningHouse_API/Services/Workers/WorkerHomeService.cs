using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Companies;
using CleaningHouse_API.Models.Customers;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Workers;

public class WorkerHomeService : IWorkerHomeService
{
    private readonly ApplicationDbContext _context;

    public WorkerHomeService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<WorkerCardDto>> GetAvailableWorkersAsync(
        DateOnly selectedDate,
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var day = selectedDate.ToDateTime(TimeOnly.MinValue);
        var busyIds = await GetBusyWorkerIdsForCalendarDayAsync(day, cancellationToken);
        var today = WorkerAvailabilityLabels.TodayUtc();

        var (page, pageSize, skip) = pagination.Normalize();

        var baseQuery = HomeScreenWorkersQuery().Where(w => !busyIds.Contains(w.Id));

        var totalCount = await baseQuery.CountAsync(cancellationToken);

        var workers = await baseQuery
            .OrderBy(w => w.FullName)
            .Skip(skip)
            .Take(pageSize)
            .Select(w => new WorkerListRow(
                w.Id,
                w.FullName,
                w.CompanyId,
                w.Company!.Name,
                w.ProfileImage))
            .ToListAsync(cancellationToken);

        var ratings = await LoadRatingStatsAsync(workers.Select(w => w.Id), cancellationToken);
        var label = WorkerAvailabilityLabels.ForDate(selectedDate, today);

        var items = workers.Select(w =>
        {
            ratings.TryGetValue(w.Id, out var stat);
            return MapCard(w, stat.Average, stat.Count, selectedDate, label,
                isAvailable: true,
                isAvailableToday: selectedDate == today ? true : null);
        }).ToList();

        return PagedResult<WorkerCardDto>.Create(items, page, pageSize, totalCount);
    }

    public async Task<PagedResult<WorkerCardDto>> GetTopRatedWorkersAsync(
        PaginationParams pagination,
        CancellationToken cancellationToken = default)
    {
        var today = WorkerAvailabilityLabels.TodayUtc();
        var todayDt = today.ToDateTime(TimeOnly.MinValue);
        var (page, pageSize, skip) = pagination.Normalize();

        var workers = await HomeScreenWorkersQuery()
            .OrderBy(w => w.FullName)
            .Select(w => new WorkerListRow(
                w.Id,
                w.FullName,
                w.CompanyId,
                w.Company!.Name,
                w.ProfileImage))
            .ToListAsync(cancellationToken);

        var ratings = await LoadRatingStatsAsync(workers.Select(w => w.Id), cancellationToken);

        var ranked = workers
            .Select(w =>
            {
                ratings.TryGetValue(w.Id, out var stat);
                return new RankedWorkerRow(
                    w.Id,
                    w.FullName,
                    w.CompanyId,
                    w.CompanyName,
                    w.ProfileImage,
                    stat.Average,
                    stat.Count);
            })
            .OrderByDescending(w => w.Rating)
            .ThenByDescending(w => w.ReviewCount)
            .ThenBy(w => w.FullName)
            .ToList();

        var totalCount = ranked.Count;
        var pageRows = ranked.Skip(skip).Take(pageSize).ToList();

        if (pageRows.Count == 0)
            return PagedResult<WorkerCardDto>.Create(Array.Empty<WorkerCardDto>(), page, pageSize, totalCount);

        var workerIds = pageRows.Select(w => w.Id).ToList();
        var schedules = await LoadActiveSchedulesForWorkersAsync(workerIds, todayDt, cancellationToken);
        var schedulesByWorker = schedules.GroupBy(s => s.WorkerId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var items = pageRows.Select(row =>
        {
            schedulesByWorker.TryGetValue(row.Id, out var workerSchedules);
            workerSchedules ??= [];

            var busyDays = WorkerAvailabilityCalculator.GetBusyCalendarDays(workerSchedules);
            var isAvailableToday = !busyDays.Contains(todayDt);
            DateOnly nextDate;
            string label;

            if (isAvailableToday)
            {
                nextDate = today;
                label = WorkerAvailabilityLabels.ForDate(today, today);
            }
            else
            {
                var found = WorkerAvailabilityCalculator.FindNextAvailableDate(busyDays, today.AddDays(1));
                nextDate = found ?? today.AddDays(1);
                label = WorkerAvailabilityLabels.ForDate(nextDate, today);
            }

            return new WorkerCardDto
            {
                Id = row.Id,
                Name = row.FullName,
                CompanyId = row.CompanyId,
                CompanyName = row.CompanyName,
                ProfileImageUrl = row.ProfileImage,
                Rating = Math.Round(row.Rating, 1),
                ReviewCount = row.ReviewCount,
                IsAvailableToday = isAvailableToday,
                NextAvailableDate = nextDate,
                AvailabilityLabel = label
            };
        }).ToList();

        return PagedResult<WorkerCardDto>.Create(items, page, pageSize, totalCount);
    }

    private IQueryable<Models.Companies.Worker> HomeScreenWorkersQuery() =>
        _context.Workers.AsNoTracking()
            .Where(w => w.IsActive
                && w.IsAvailable
                && w.Company != null
                && w.Company.IsActive
                && w.Company.IsVerified);

    private async Task<HashSet<int>> GetBusyWorkerIdsForCalendarDayAsync(
        DateTime calendarDay,
        CancellationToken cancellationToken)
    {
        var schedules = await LoadActiveSchedulesInWindowAsync(calendarDay, cancellationToken);
        return WorkerAvailabilityCalculator.GetBusyWorkerIdsForDay(schedules, calendarDay);
    }

    private async Task<List<WorkerBookingSchedule>> LoadActiveSchedulesInWindowAsync(
        DateTime centerDay,
        CancellationToken cancellationToken)
    {
        var (windowStart, windowEnd) = WorkerAvailabilityCalculator.BookingLookupWindow(centerDay);

        return await _context.Bookings
            .AsNoTracking()
            .Where(b => b.Status == BookingStatuses.Pending
                || b.Status == BookingStatuses.Approved
                || b.Status == BookingStatuses.OnTheWay)
            .Where(b => b.BookingDate >= windowStart && b.BookingDate <= windowEnd)
            .Select(b => new WorkerBookingSchedule(
                b.WorkerId,
                b.BookingDate,
                b.StartDate,
                b.EndDate))
            .ToListAsync(cancellationToken);
    }

    private async Task<List<WorkerBookingSchedule>> LoadActiveSchedulesForWorkersAsync(
        IReadOnlyList<int> workerIds,
        DateTime referenceDay,
        CancellationToken cancellationToken)
    {
        if (workerIds.Count == 0)
            return [];

        var (windowStart, windowEnd) = WorkerAvailabilityCalculator.BookingLookupWindow(referenceDay);

        return await _context.Bookings
            .AsNoTracking()
            .Where(b => workerIds.Contains(b.WorkerId))
            .Where(b => b.Status == BookingStatuses.Pending
                || b.Status == BookingStatuses.Approved
                || b.Status == BookingStatuses.OnTheWay)
            .Where(b => b.BookingDate >= windowStart && b.BookingDate <= windowEnd)
            .Select(b => new WorkerBookingSchedule(
                b.WorkerId,
                b.BookingDate,
                b.StartDate,
                b.EndDate))
            .ToListAsync(cancellationToken);
    }

    private async Task<Dictionary<int, (double Average, int Count)>> LoadRatingStatsAsync(
        IEnumerable<int> workerIds,
        CancellationToken cancellationToken)
    {
        var ids = workerIds.Distinct().ToList();
        if (ids.Count == 0)
            return new Dictionary<int, (double, int)>();

        var stats = await _context.Reviews
            .AsNoTracking()
            .Where(r => ids.Contains(r.WorkerId))
            .GroupBy(r => r.WorkerId)
            .Select(g => new RatingStatRow(
                g.Key,
                g.Average(r => (double)r.Rating),
                g.Count()))
            .ToListAsync(cancellationToken);

        return stats.ToDictionary(s => s.WorkerId, s => (s.AverageRating, s.ReviewCount));
    }

    private static WorkerCardDto MapCard(
        WorkerListRow row,
        double rating,
        int reviewCount,
        DateOnly availableDate,
        string label,
        bool? isAvailable,
        bool? isAvailableToday)
    {
        return new WorkerCardDto
        {
            Id = row.Id,
            Name = row.FullName,
            CompanyId = row.CompanyId,
            CompanyName = row.CompanyName,
            ProfileImageUrl = row.ProfileImage,
            Rating = Math.Round(rating, 1),
            ReviewCount = reviewCount,
            IsAvailable = isAvailable,
            IsAvailableToday = isAvailableToday,
            AvailableDate = availableDate,
            AvailabilityLabel = label
        };
    }

    private sealed record WorkerListRow(
        int Id,
        string FullName,
        int CompanyId,
        string CompanyName,
        string? ProfileImage);

    private sealed record RankedWorkerRow(
        int Id,
        string FullName,
        int CompanyId,
        string CompanyName,
        string? ProfileImage,
        double Rating,
        int ReviewCount);

    private sealed record RatingStatRow(int WorkerId, double AverageRating, int ReviewCount);
}

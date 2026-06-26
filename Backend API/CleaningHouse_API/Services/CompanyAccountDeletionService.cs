using CleaningHouse_API.Authentication;
using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Customers;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services;

public class CompanyAccountDeletionService : ICompanyAccountDeletionService
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<CompanyAccountDeletionService> _logger;

    public CompanyAccountDeletionService(
        ApplicationDbContext context,
        IWebHostEnvironment env,
        ILogger<CompanyAccountDeletionService> logger)
    {
        _context = context;
        _env = env;
        _logger = logger;
    }

    public async Task<CompanyAccountDeletionResult> DeleteCompanyAccountAsync(
        int userId,
        string? password,
        bool requirePassword,
        CancellationToken cancellationToken = default)
    {
        var user = await _context.AppUsers
            .Include(u => u.UserType)
            .FirstOrDefaultAsync(u => u.Id == userId && u.IsActive, cancellationToken);

        if (user == null)
            return CompanyAccountDeletionResult.UserNotFound;

        if (!string.Equals(user.UserType?.Name, AppRoles.Company, StringComparison.OrdinalIgnoreCase))
            return CompanyAccountDeletionResult.NotCompanyUser;

        if (requirePassword)
        {
            if (string.IsNullOrWhiteSpace(password)
                || string.IsNullOrWhiteSpace(user.PasswordHash)
                || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            {
                return CompanyAccountDeletionResult.InvalidPassword;
            }
        }

        var companyIds = await _context.Companies
            .Where(c => c.OwnerUserId == userId)
            .Select(c => c.Id)
            .ToListAsync(cancellationToken);

        if (companyIds.Count > 0)
        {
            var hasActiveBookings = await _context.Bookings
                .AnyAsync(
                    b => companyIds.Contains(b.CompanyId)
                        && (b.Status == BookingStatuses.Pending
                            || b.Status == BookingStatuses.Approved
                            || b.Status == BookingStatuses.OnTheWay),
                    cancellationToken);

            if (hasActiveBookings)
                return CompanyAccountDeletionResult.ActiveBookingsExist;
        }

        var commercialRegisterDirs = new List<string>();

        async Task ApplyDeletionAsync()
        {
            if (companyIds.Count > 0)
            {
                var companies = await _context.Companies
                    .Where(c => companyIds.Contains(c.Id))
                    .ToListAsync(cancellationToken);

                foreach (var company in companies)
                {
                    if (!string.IsNullOrWhiteSpace(company.CommercialRegisterURL))
                    {
                        commercialRegisterDirs.Add(
                            Path.Combine(
                                _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"),
                                "uploads",
                                "commercial-registers",
                                company.Id.ToString()));
                    }

                    company.IsActive = false;
                    company.IsVerified = false;
                    company.Name = $"Deleted Company {company.Id}";
                    company.Email = $"deleted-company-{company.Id}@internal.deleted";
                    company.Phone = $"deleted-{company.Id}";
                    company.Address = null;
                    company.CommercialRegNo = null;
                    company.Description = null;
                    company.CommercialRegisterURL = null;
                }

                var workers = await _context.Workers
                    .Where(w => companyIds.Contains(w.CompanyId) && w.IsActive)
                    .ToListAsync(cancellationToken);

                foreach (var worker in workers)
                    worker.IsActive = false;

                var workTypes = await _context.WorkTypes
                    .Where(wt => companyIds.Contains(wt.CompanyId) && wt.IsActive)
                    .ToListAsync(cancellationToken);

                foreach (var workType in workTypes)
                    workType.IsActive = false;
            }

            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsDeleted)
                .ToListAsync(cancellationToken);

            foreach (var notification in notifications)
                notification.IsDeleted = true;

            var resetTokens = await _context.PasswordResetTokens
                .Where(t => t.UserId == userId)
                .ToListAsync(cancellationToken);

            _context.PasswordResetTokens.RemoveRange(resetTokens);

            var now = DateTime.UtcNow;
            user.IsActive = false;
            user.DeletedAt = now;
            user.PasswordHash = null;
            user.FullName = "Deleted User";
            user.Email = $"deleted-user-{user.Id}@internal.deleted";
            user.Phone = null;

            await _context.SaveChangesAsync(cancellationToken);
        }

        if (_context.Database.IsRelational())
        {
            await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                await ApplyDeletionAsync();
                await transaction.CommitAsync(cancellationToken);
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }
        else
        {
            await ApplyDeletionAsync();
        }

        foreach (var dir in commercialRegisterDirs.Distinct())
        {
            try
            {
                if (Directory.Exists(dir))
                    Directory.Delete(dir, recursive: true);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to delete commercial register files at {Dir}", dir);
            }
        }

        _logger.LogInformation("Company account {UserId} deleted safely", userId);
        return CompanyAccountDeletionResult.Success;
    }
}

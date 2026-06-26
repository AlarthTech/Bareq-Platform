using CleaningHouse_API.Data;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Authentication;

public static class CompanyAccess
{
    public static Task<bool> UserOwnsCompanyAsync(ApplicationDbContext db, int userId, int companyId) =>
        db.Companies.AnyAsync(c => c.Id == companyId && c.OwnerUserId == userId);

    public static async Task<bool> UserOwnsWorkerAsync(ApplicationDbContext db, int userId, int workerId)
    {
        var companyId = await db.Workers
            .Where(w => w.Id == workerId)
            .Select(w => (int?)w.CompanyId)
            .FirstOrDefaultAsync();
        if (companyId is null)
            return false;
        return await UserOwnsCompanyAsync(db, userId, companyId.Value);
    }
}

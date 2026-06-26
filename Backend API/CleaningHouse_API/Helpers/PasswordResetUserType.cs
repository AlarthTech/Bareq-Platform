using CleaningHouse_API.Authentication;
using CleaningHouse_API.Services;

namespace CleaningHouse_API.Helpers;

public static class PasswordResetUserType
{
    public const string Customer = AppRoles.Customer;
    public const string Company = AppRoles.Company;

    public static string Normalize(string? userType)
    {
        var role = JwtService.NormalizeRoleName(userType?.Trim());
        return role ?? Customer;
    }

    public static bool IsCompany(string normalizedUserType) =>
        string.Equals(normalizedUserType, Company, StringComparison.OrdinalIgnoreCase);
}

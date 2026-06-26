using System.Security.Claims;

namespace CleaningHouse_API.Authentication;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal user)
    {
        var id = user.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(id, out var value) ? value : null;
    }

    public static bool IsAdmin(this ClaimsPrincipal user) =>
        user.IsInRole(AppRoles.Admin);
}

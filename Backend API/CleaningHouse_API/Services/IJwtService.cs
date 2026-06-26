using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Services;

public interface IJwtService
{
    string GenerateToken(AppUser user);
    int? ValidateToken(string token);
}


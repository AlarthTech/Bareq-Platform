using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.Services;

public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public static string? NormalizeRoleName(string? userTypeName)
    {
        if (string.IsNullOrWhiteSpace(userTypeName))
            return null;
        return userTypeName.Trim().ToLowerInvariant() switch
        {
            "admin" => AppRoles.Admin,
            "company" or "companyowner" => AppRoles.Company,
            "customer" => AppRoles.Customer,
            _ => null
        };
    }

    public string GenerateToken(AppUser user)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("JWT SecretKey not configured");
        var issuer = jwtSettings["Issuer"] ?? "CleaningHouseAPI";
        var audience = jwtSettings["Audience"] ?? "CleaningHouseClient";
        var expirationMinutes = int.Parse(jwtSettings["ExpirationMinutes"] ?? "1440"); // Default 24 hours

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var role = NormalizeRoleName(user.UserType?.Name);
        if (role is null)
            throw new InvalidOperationException("User type is missing or not mapped to an application role. Ensure UserType is loaded on login.");

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, role),
            new Claim("UserTypeId", user.UserTypeId.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims.ToArray(),
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public int? ValidateToken(string token)
    {
        try
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("JWT SecretKey not configured");
            var issuer = jwtSettings["Issuer"] ?? "CleaningHouseAPI";
            var audience = jwtSettings["Audience"] ?? "CleaningHouseClient";

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(secretKey);

            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuer = true,
                ValidIssuer = issuer,
                ValidateAudience = true,
                ValidAudience = audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero,
                RoleClaimType = ClaimTypes.Role
            };

            var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
            var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim != null && int.TryParse(userIdClaim.Value, out int userId))
            {
                return userId;
            }

            return null;
        }
        catch
        {
            return null;
        }
    }
}



using System.Security.Cryptography;

namespace CleaningHouse_API.Helpers;

public static class ResetTokenGenerator
{
    public static string GenerateSixDigitOtp()
    {
        var value = RandomNumberGenerator.GetInt32(0, 1_000_000);
        return value.ToString("D6");
    }

    public static string GenerateResetToken() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
}

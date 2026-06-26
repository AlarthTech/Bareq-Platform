namespace CleaningHouse_API.Helpers;

public static class SecureHashing
{
    public static string HashSecret(string value) =>
        BCrypt.Net.BCrypt.HashPassword(value, workFactor: 12);

    public static bool VerifySecret(string value, string hash) =>
        BCrypt.Net.BCrypt.Verify(value, hash);
}

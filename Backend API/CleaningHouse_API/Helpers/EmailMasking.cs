namespace CleaningHouse_API.Helpers;

public static class EmailMasking
{
    public static string Mask(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return "***";

        var at = email.IndexOf('@');
        if (at <= 0)
            return "***";

        var local = email[..at];
        var domain = email[(at + 1)..];
        var visible = local.Length <= 2 ? "*" : local[..2];
        return $"{visible}***@{domain}";
    }
}

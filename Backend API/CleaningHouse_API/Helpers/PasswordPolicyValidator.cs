using System.Text.RegularExpressions;

namespace CleaningHouse_API.Helpers;

public static partial class PasswordPolicyValidator
{
    public const string WeakPasswordMessage =
        "كلمة المرور يجب أن تكون 8 أحرف على الأقل وتحتوي على حرف كبير وحرف صغير ورقم.";

    public static bool IsValid(string password) => TryValidate(password, out _);

    public static bool TryValidate(string password, out string? errorMessage)
    {
        errorMessage = null;

        if (string.IsNullOrEmpty(password) || password.Length < 8)
        {
            errorMessage = WeakPasswordMessage;
            return false;
        }

        if (!password.Any(char.IsUpper))
        {
            errorMessage = WeakPasswordMessage;
            return false;
        }

        if (!password.Any(char.IsLower))
        {
            errorMessage = WeakPasswordMessage;
            return false;
        }

        if (!password.Any(char.IsDigit))
        {
            errorMessage = WeakPasswordMessage;
            return false;
        }

        return true;
    }
}

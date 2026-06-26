using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace CleaningHouse_API.DTOs.Common;

public class ForgotPasswordRequestDto
{
    [Required(ErrorMessage = "البريد الإلكتروني مطلوب.")]
    [MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    /// <summary>Customer (default) or Company — must match the app requesting reset.</summary>
    [MaxLength(32)]
    [JsonPropertyName("userType")]
    public string UserType { get; set; } = "Customer";

    /// <summary>Flutter snake_case alias for userType.</summary>
    [JsonPropertyName("user_type")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public string? UserTypeSnake
    {
        set
        {
            if (!string.IsNullOrWhiteSpace(value))
                UserType = value;
        }
    }
}

public class ForgotPasswordResponseDto
{
    public string Message { get; set; } = "إذا كان البريد الإلكتروني مسجلاً لدينا، سيتم إرسال رمز التحقق.";
}

public class VerifyResetCodeRequestDto
{
    [Required(ErrorMessage = "البريد الإلكتروني مطلوب.")]
    [MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "رمز التحقق مطلوب.")]
    [RegularExpression(@"^\d{6}$", ErrorMessage = "رمز التحقق يجب أن يكون 6 أرقام.")]
    public string Code { get; set; } = string.Empty;

    /// <summary>Customer (default) or Company.</summary>
    [MaxLength(32)]
    [JsonPropertyName("userType")]
    public string UserType { get; set; } = "Customer";

    [JsonPropertyName("user_type")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public string? UserTypeSnake
    {
        set
        {
            if (!string.IsNullOrWhiteSpace(value))
                UserType = value;
        }
    }
}

public class VerifyResetCodeResponseDto
{
    public string ResetToken { get; set; } = string.Empty;
}

public class ResetPasswordRequestDto
{
    [Required(ErrorMessage = "البريد الإلكتروني مطلوب.")]
    [MaxLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "رمز إعادة التعيين مطلوب.")]
    public string ResetToken { get; set; } = string.Empty;

    [Required(ErrorMessage = "كلمة المرور الجديدة مطلوبة.")]
    public string NewPassword { get; set; } = string.Empty;

    /// <summary>Customer (default) or Company.</summary>
    [MaxLength(32)]
    [JsonPropertyName("userType")]
    public string UserType { get; set; } = "Customer";

    [JsonPropertyName("user_type")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public string? UserTypeSnake
    {
        set
        {
            if (!string.IsNullOrWhiteSpace(value))
                UserType = value;
        }
    }
}

public class MessageResponseDto
{
    public string Message { get; set; } = string.Empty;
}

public class TestEmailRequestDto
{
    [Required(ErrorMessage = "البريد الإلكتروني مطلوب.")]
    [EmailAddress(ErrorMessage = "البريد الإلكتروني غير صالح.")]
    [MaxLength(256)]
    public string ToEmail { get; set; } = string.Empty;

    /// <summary>
    /// Optional: password-reset-otp | company-password-reset-otp | welcome | password-changed | auto-reply
    /// </summary>
    [MaxLength(64)]
    public string? Template { get; set; }
}

public class TestEmailResponseDto
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}

using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace CleaningHouse_API.DTOs.Admin;

public class PlatformFeeResponseDTO
{
    public decimal FixedPlatformFeeAmount { get; set; }

    /// <summary>Alias for admin clients that send/read <c>amount</c>.</summary>
    [JsonPropertyName("amount")]
    public decimal Amount => FixedPlatformFeeAmount;
}

public class UpdatePlatformFeeRequestDTO : IValidatableObject
{
    [Range(0, double.MaxValue, ErrorMessage = "رسوم المنصة يجب أن تكون أكبر من أو تساوي صفر")]
    public decimal? FixedPlatformFeeAmount { get; set; }

    /// <summary>Alias accepted from admin dashboard (<c>{ "amount": 10 }</c>).</summary>
    [Range(0, double.MaxValue, ErrorMessage = "رسوم المنصة يجب أن تكون أكبر من أو تساوي صفر")]
    public decimal? Amount { get; set; }

    public decimal ResolveAmount() => Amount ?? FixedPlatformFeeAmount ?? 0m;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!Amount.HasValue && !FixedPlatformFeeAmount.HasValue)
        {
            yield return new ValidationResult(
                "يجب إرسال amount أو fixedPlatformFeeAmount.",
                [nameof(Amount), nameof(FixedPlatformFeeAmount)]);
        }
    }
}

public class UpdatePlatformFeeResponseDTO
{
    public bool Success { get; set; } = true;
    public decimal FixedPlatformFeeAmount { get; set; }

    [JsonPropertyName("amount")]
    public decimal Amount => FixedPlatformFeeAmount;
}

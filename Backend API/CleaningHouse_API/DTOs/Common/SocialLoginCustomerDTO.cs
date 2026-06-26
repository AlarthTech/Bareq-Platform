using System.ComponentModel.DataAnnotations;
using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.DTOs.Common;

public class SocialLoginCustomerDTO
{
    [Required]
    public ExternalAuthProvider Provider { get; set; }

    /// <summary>Google and Apple identity token.</summary>
    public string? IdToken { get; set; }

    /// <summary>Facebook user access token.</summary>
    public string? AccessToken { get; set; }

    [MaxLength(200)]
    public string? FullName { get; set; }

    [MaxLength(20)]
    public string? Phone { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Common;

public class DeleteMyCompanyAccountDTO
{
    [Required(ErrorMessage = "كلمة المرور مطلوبة.")]
    public string Password { get; set; } = string.Empty;
}

using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Common;

public class AppUserDTO
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Email { get; set; } = string.Empty;
    public int UserTypeId { get; set; }
    public string? UserTypeName { get; set; }
    public int? CityId { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateAppUserDTO
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;

    [Required]
    public int UserTypeId { get; set; }
}

public class UpdateAppUserDTO
{
    [MaxLength(200)]
    public string? FullName { get; set; }

    [MaxLength(20)]
    public string? Phone { get; set; }

    [MaxLength(100)]
    [EmailAddress]
    public string? Email { get; set; }

    [MinLength(6)]
    public string? Password { get; set; }
}

// DTOs for specific user types
public class CreateCustomerDTO
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;

    public int? CityId { get; set; }
}

public class CreateCompanyOwnerDTO
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;

    public int? CityId { get; set; }
}

public class CreateAdminDTO
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;

    public int? CityId { get; set; }
}

// Login DTOs
public class LoginDTO
{
    [Required]
    public string Username { get; set; } = string.Empty; // Can be email or phone

    [Required]
    public string Password { get; set; } = string.Empty;

    [Required]
    public string UserType { get; set; } = string.Empty; // Customer, CompanyOwner, Admin
}

public class LoginResponseDTO
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public string? Token { get; set; }
    public AppUserDTO? User { get; set; }
    public bool IsNewUser { get; set; }
    public bool RequiresProfileCompletion { get; set; }
}

public class ChangePasswordDTO
{
    [Required]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required]
    [MinLength(6)]
    public string NewPassword { get; set; } = string.Empty;
}

public class ChangePersonalInfoDTO
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}

public class ChangePhoneNumberDTO
{
    [Required]
    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    public int? CityId { get; set; }
}



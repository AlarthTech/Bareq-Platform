using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using AutoMapper;
using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Helpers;
using CleaningHouse_API.Services;
using CleaningHouse_API.Services.Email;
using CleaningHouse_API.Services.SocialAuth;

namespace CleaningHouse_API.Controllers.Common;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AppUsersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;
    private readonly IJwtService _jwtService;
    private readonly IPasswordResetService _passwordResetService;
    private readonly IEmailSender _emailSender;
    private readonly ITransactionalEmailQueue _emailQueue;
    private readonly ICustomerSocialLoginService _customerSocialLoginService;
    private readonly ICompanyAccountDeletionService _companyAccountDeletionService;
    private readonly ILogger<AppUsersController> _logger;

    public AppUsersController(
        ApplicationDbContext context,
        IMapper mapper,
        IJwtService jwtService,
        IPasswordResetService passwordResetService,
        IEmailSender emailSender,
        ITransactionalEmailQueue emailQueue,
        ICustomerSocialLoginService customerSocialLoginService,
        ICompanyAccountDeletionService companyAccountDeletionService,
        ILogger<AppUsersController> logger)
    {
        _context = context;
        _mapper = mapper;
        _jwtService = jwtService;
        _passwordResetService = passwordResetService;
        _emailSender = emailSender;
        _emailQueue = emailQueue;
        _customerSocialLoginService = customerSocialLoginService;
        _companyAccountDeletionService = companyAccountDeletionService;
        _logger = logger;
    }

    // GET: api/AppUsers/GetAllAppUsers
    [HttpGet("GetAllAppUsers")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(PagedResult<AppUserDTO>), 200)]
    public async Task<ActionResult<PagedResult<AppUserDTO>>> GetAllAppUsers([FromQuery] PaginationParams pagination)
    {
        var query = _context.AppUsers.AsNoTracking()
            .Where(u => u.IsActive)
            .Include(u => u.UserType)
            .Include(u => u.City)
            .OrderByDescending(u => u.CreatedAt);

        var (page, pageSize, skip) = pagination.Normalize();
        var totalCount = await query.CountAsync();
        var appUsers = await query.Skip(skip).Take(pageSize).ToListAsync();
        var items = _mapper.Map<List<AppUserDTO>>(appUsers);
        return Ok(PagedResult<AppUserDTO>.Create(items, page, pageSize, totalCount));
    }

    // GET: api/AppUsers/GetAppUserById/{id}
    [HttpGet("GetAppUserById/{id}")]
    public async Task<ActionResult<AppUserDTO>> GetAppUserById(int id)
    {
        if (!User.IsAdmin() && User.GetUserId() != id)
            return Forbid();

        var appUser = await _context.AppUsers.AsNoTracking()
            .Where(u => u.Id == id && u.IsActive)
            .Include(u => u.UserType)
               .Include(u => u.City)
            .FirstOrDefaultAsync();

        if (appUser == null)
        {
            return NotFound();
        }

        return Ok(_mapper.Map<AppUserDTO>(appUser));
    }



    // POST: api/AppUsers/Login
    [HttpPost("Login")]
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<LoginResponseDTO>> Login(LoginDTO loginDTO)
    {
        // Validate input
        if (string.IsNullOrWhiteSpace(loginDTO.Username) || string.IsNullOrWhiteSpace(loginDTO.Password))
        {
            return BadRequest(new LoginResponseDTO
            {
                Success = false,
                Message = "اسم المستخدم وكلمة المرور مطلوبان"
            });
        }

        // Get UserType by name (Admin, Company, Customer)
        var userType = await _context.UserTypes
            .Where(ut => ut.IsActive && ut.Name.ToLower() == loginDTO.UserType.ToLower())
            .FirstOrDefaultAsync();

        if (userType == null)
        {
            return BadRequest(new LoginResponseDTO
            {
                Success = false,
                Message = "نوع المستخدم غير صحيح. يجب أن يكون: Admin أو Company أو Customer"
            });
        }

        // Find user by email or phone
        var appUser = await _context.AppUsers
            .Include(u => u.UserType)
            .FirstOrDefaultAsync(u => (u.Email == loginDTO.Username || u.Phone == loginDTO.Username) &&
                                      u.UserTypeId == userType.Id &&
                                      u.IsActive);

        if (appUser == null)
        {
            return Unauthorized(new LoginResponseDTO
            {
                Success = false,
                Message = "اسم المستخدم أو كلمة المرور غير صحيحة"
            });
        }

        if (string.Equals(loginDTO.UserType, AppRoles.Customer, StringComparison.OrdinalIgnoreCase)
            && string.IsNullOrWhiteSpace(appUser.PasswordHash))
        {
            return BadRequest(new LoginResponseDTO
            {
                Success = false,
                Message = "هذا الحساب مسجل عبر Google/Apple/Facebook — استخدم تسجيل الدخول الاجتماعي"
            });
        }

        // Verify password
        bool isPasswordValid = BCrypt.Net.BCrypt.Verify(loginDTO.Password, appUser.PasswordHash ?? string.Empty);
        if (!isPasswordValid)
        {
            return Unauthorized(new LoginResponseDTO
            {
                Success = false,
                Message = "اسم المستخدم أو كلمة المرور غير صحيحة"
            });
        }

        // Generate JWT Token
        var token = _jwtService.GenerateToken(appUser);

        // Login successful
        var appUserDTO = _mapper.Map<AppUserDTO>(appUser);
        return Ok(new LoginResponseDTO
        {
            Success = true,
            Message = "تم تسجيل الدخول بنجاح",
            Token = token,
            User = appUserDTO
        });
    }

    // POST: api/AppUsers/SocialLoginCustomer
    [HttpPost("SocialLoginCustomer")]
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(LoginResponseDTO), 200)]
    [ProducesResponseType(typeof(LoginResponseDTO), 400)]
    [ProducesResponseType(typeof(LoginResponseDTO), 401)]
    [ProducesResponseType(typeof(LoginResponseDTO), 409)]
    public async Task<ActionResult<LoginResponseDTO>> SocialLoginCustomer(
        [FromBody] SocialLoginCustomerDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var result = await _customerSocialLoginService.LoginAsync(dto, cancellationToken);

        return result.Status switch
        {
            CustomerSocialLoginStatus.Success => Ok(result.Response),
            CustomerSocialLoginStatus.InvalidProvider => BadRequest(new LoginResponseDTO
            {
                Success = false,
                Message = "مزود تسجيل الدخول غير مدعوم"
            }),
            CustomerSocialLoginStatus.InvalidToken => Unauthorized(new LoginResponseDTO
            {
                Success = false,
                Message = "رمز تسجيل الدخول الاجتماعي غير صالح أو منتهي الصلاحية"
            }),
            CustomerSocialLoginStatus.EmailRequired => BadRequest(new LoginResponseDTO
            {
                Success = false,
                Message = "البريد الإلكتروني مطلوب من مزود تسجيل الدخول"
            }),
            CustomerSocialLoginStatus.EmailAlreadyUsed => BadRequest(new LoginResponseDTO
            {
                Success = false,
                Message = "البريد الإلكتروني أو رقم الهاتف مستخدم بالفعل"
            }),
            CustomerSocialLoginStatus.EmailConflictWithPasswordAccount => Conflict(new LoginResponseDTO
            {
                Success = false,
                Message = "الحساب مسجل بكلمة مرور — سجّل الدخول بالبريد أو اربط الحساب"
            }),
            _ => Unauthorized(new LoginResponseDTO
            {
                Success = false,
                Message = "فشل تسجيل الدخول الاجتماعي"
            })
        };
    }



    // POST: api/AppUsers/CreateNewAdmin
    [HttpPost("CreateNewAdmin")]
    [AllowAnonymous]
    [EnableRateLimiting("registration")]
    public async Task<ActionResult<AppUserDTO>> CreateNewAdmin(CreateAdminDTO createAdminDTO)
    {
        var adminUserType = await _context.UserTypes.FirstOrDefaultAsync(ut => ut.Name.ToLower() == "admin");
        if (adminUserType != null)
        {
            var anyActiveAdmin = await _context.AppUsers.AnyAsync(u => u.UserTypeId == adminUserType.Id && u.IsActive);
            if (anyActiveAdmin)
            {
                if (!(User.Identity?.IsAuthenticated ?? false))
                    return Unauthorized();
                if (!User.IsAdmin())
                    return Forbid();
            }
        }

        // Check if email already exists
        if (await _context.AppUsers.AnyAsync(u => u.Email == createAdminDTO.Email))
        {
            return BadRequest("البريد الإلكتروني مستخدم بالفعل");
        }

        // Check if phone already exists
        if (await _context.AppUsers.AnyAsync(u => u.Phone == createAdminDTO.Phone))
        {
            return BadRequest("رقم الهاتف مستخدم بالفعل");
        }

        if (adminUserType == null)
        {
            return BadRequest("نوع المستخدم (Admin) غير موجود في النظام");
        }

        var appUser = new AppUser
        {
            FullName = createAdminDTO.FullName,
            Phone = createAdminDTO.Phone,
            Email = createAdminDTO.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(createAdminDTO.Password),
            UserTypeId = adminUserType.Id,
            CityId = createAdminDTO.CityId,
            CreatedAt = DateTime.UtcNow
        };

        _context.AppUsers.Add(appUser);
        await _context.SaveChangesAsync();

        // Load UserType and City for mapping
        await _context.Entry(appUser).Reference(u => u.UserType).LoadAsync();
        await _context.Entry(appUser).Reference(u => u.City).LoadAsync();
        var appUserDTO = _mapper.Map<AppUserDTO>(appUser);
        return CreatedAtAction(nameof(GetAppUserById), new { id = appUser.Id }, appUserDTO);
    }



    // POST: api/AppUsers/CreateNewCompanyOwner
    [HttpPost("CreateNewCompanyOwner")]
    [AllowAnonymous]
    [EnableRateLimiting("registration")]
    public async Task<ActionResult<AppUserDTO>> CreateNewCompanyOwner(CreateCompanyOwnerDTO createCompanyOwnerDTO)
    {
        // Check if email already exists
        if (await _context.AppUsers.AnyAsync(u => u.Email == createCompanyOwnerDTO.Email))
        {
            return BadRequest("البريد الإلكتروني مستخدم بالفعل");
        }

        // Check if phone already exists
        if (await _context.AppUsers.AnyAsync(u => u.Phone == createCompanyOwnerDTO.Phone))
        {
            return BadRequest("رقم الهاتف مستخدم بالفعل");
        }

        // Get CompanyOwner UserTypeId
        var companyOwnerUserType = await _context.UserTypes
            .FirstOrDefaultAsync(ut => ut.Name.ToLower() == "Company");    ///       == 1=  Company

        if (companyOwnerUserType == null)
        {
            return BadRequest("نوع المستخدم (صاحب شركة) غير موجود في النظام");
        }

        var appUser = new AppUser
        {
            FullName = createCompanyOwnerDTO.FullName,
            Phone = createCompanyOwnerDTO.Phone,
            Email = createCompanyOwnerDTO.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(createCompanyOwnerDTO.Password),
            UserTypeId = companyOwnerUserType.Id,
            CityId = createCompanyOwnerDTO.CityId,
            CreatedAt = DateTime.UtcNow
        };

        _context.AppUsers.Add(appUser);
        await _context.SaveChangesAsync();

        // Load UserType and City for mapping
        await _context.Entry(appUser).Reference(u => u.UserType).LoadAsync();
        await _context.Entry(appUser).Reference(u => u.City).LoadAsync();
        var appUserDTO = _mapper.Map<AppUserDTO>(appUser);
        return CreatedAtAction(nameof(GetAppUserById), new { id = appUser.Id }, appUserDTO);
    }






    // POST: api/AppUsers/CreateNewCustomer
    [HttpPost("CreateNewCustomer")]
    [AllowAnonymous]
    [EnableRateLimiting("registration")]
    public async Task<ActionResult<AppUserDTO>> CreateNewCustomer(CreateCustomerDTO createCustomerDTO)
    {
        // Check if email already exists
        if (await _context.AppUsers.AnyAsync(u => u.Email == createCustomerDTO.Email))
        {
            return BadRequest("البريد الإلكتروني مستخدم بالفعل");
        }

        // Check if phone already exists
        if (await _context.AppUsers.AnyAsync(u => u.Phone == createCustomerDTO.Phone))
        {
            return BadRequest("رقم الهاتف مستخدم بالفعل");
        }

        // Get Customer UserTypeId
        var customerUserType = await _context.UserTypes
            .FirstOrDefaultAsync(ut => ut.Name.ToLower() == "Customer");  ///       == 1=  Customer 

        if (customerUserType == null)
        {
            return BadRequest("نوع المستخدم (Customer) غير موجود في النظام");
        }

        var appUser = new AppUser
        {
            FullName = createCustomerDTO.FullName,
            Phone = createCustomerDTO.Phone,
            Email = createCustomerDTO.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(createCustomerDTO.Password),
            UserTypeId = customerUserType.Id,
            CityId = createCustomerDTO.CityId,
            CreatedAt = DateTime.UtcNow
        };

        _context.AppUsers.Add(appUser);
        await _context.SaveChangesAsync();

        await _context.Entry(appUser).Reference(u => u.UserType).LoadAsync();
        await _context.Entry(appUser).Reference(u => u.City).LoadAsync();
        var appUserDTO = _mapper.Map<AppUserDTO>(appUser);

        _emailQueue.Enqueue(
            sender => sender.SendWelcomeEmailAsync(appUser.Email, appUser.FullName),
            "welcome",
            appUser.Email);

        return CreatedAtAction(nameof(GetAppUserById), new { id = appUser.Id }, appUserDTO);
    }

    [HttpPost("TestEmail")]
    [Authorize(Roles = AppRoles.Admin)]
    [ProducesResponseType(typeof(TestEmailResponseDto), 200)]
    [ProducesResponseType(typeof(TestEmailResponseDto), 400)]
    public async Task<ActionResult<TestEmailResponseDto>> TestEmail([FromBody] TestEmailRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            await _emailSender.SendTestEmailAsync(
                dto.ToEmail.Trim(),
                string.IsNullOrWhiteSpace(dto.Template) ? null : dto.Template.Trim(),
                HttpContext.RequestAborted);

            var message = (dto.Template?.Trim().ToLowerInvariant()) switch
            {
                "password-reset-otp" => "تم إرسال قالب OTP للعملاء (معاينة) بنجاح.",
                "company-password-reset-otp" => "تم إرسال قالب OTP للشركات (معاينة) بنجاح.",
                "welcome" => "تم إرسال قالب الترحيب بنجاح.",
                "password-changed" => "تم إرسال قالب تغيير كلمة المرور بنجاح.",
                "auto-reply" => "تم إرسال قالب الرد التلقائي بنجاح.",
                _ => "تم إرسال رسالة الاختبار بنجاح."
            };

            return Ok(new TestEmailResponseDto
            {
                Success = true,
                Message = message
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Admin SMTP test failed for {MaskedEmail}", EmailMasking.Mask(dto.ToEmail));
            return BadRequest(new TestEmailResponseDto
            {
                Success = false,
                Message = "فشل إرسال رسالة الاختبار. راجع سجلات الخادم."
            });
        }
    }

    [HttpPost("ForgotPassword")]
    [AllowAnonymous]
    [EnableRateLimiting("forgot-password")]
    [ProducesResponseType(typeof(ForgotPasswordResponseDto), 200)]
    public async Task<ActionResult<ForgotPasswordResponseDto>> ForgotPassword(
        [FromBody] ForgotPasswordRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();
        var result = await _passwordResetService.RequestOtpAsync(dto, ip, userAgent, HttpContext.RequestAborted);
        return Ok(result);
    }

    [HttpPost("VerifyResetCode")]
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(VerifyResetCodeResponseDto), 200)]
    [ProducesResponseType(typeof(MessageResponseDto), 400)]
    public async Task<ActionResult<VerifyResetCodeResponseDto>> VerifyResetCode(
        [FromBody] VerifyResetCodeRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var result = await _passwordResetService.VerifyCodeAsync(dto, HttpContext.RequestAborted);
        if (result == null)
            return BadRequest(new MessageResponseDto { Message = PasswordResetService.InvalidCodeMessage });

        return Ok(result);
    }

    [HttpPost("ResetPassword")]
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(MessageResponseDto), 200)]
    [ProducesResponseType(typeof(MessageResponseDto), 400)]
    public async Task<ActionResult<MessageResponseDto>> ResetPassword(
        [FromBody] ResetPasswordRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (!PasswordPolicyValidator.TryValidate(dto.NewPassword, out var passwordError))
            return BadRequest(new MessageResponseDto { Message = passwordError! });

        var result = await _passwordResetService.ResetPasswordAsync(dto, HttpContext.RequestAborted);
        if (result == null)
            return BadRequest(new MessageResponseDto { Message = PasswordResetService.InvalidResetTokenMessage });

        return Ok(result);
    }

    // PUT: api/AppUsers/ChangePassword
    [HttpPut("ChangePassword")]
    public async Task<IActionResult> ChangePassword(ChangePasswordDTO dto)
    {
        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized();

        var appUser = await _context.AppUsers
            .FirstOrDefaultAsync(u => u.Id == userId && u.IsActive);
        if (appUser == null)
            return NotFound();

        if (string.IsNullOrWhiteSpace(appUser.PasswordHash))
            return BadRequest("هذا الحساب مسجل عبر Google/Apple/Facebook — لا يمكن تغيير كلمة المرور هنا");

        if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, appUser.PasswordHash))
            return BadRequest("كلمة المرور الحالية غير صحيحة");

        if (dto.CurrentPassword == dto.NewPassword)
            return BadRequest("كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية");

        appUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        await _context.SaveChangesAsync();

        _emailQueue.Enqueue(
            sender => sender.SendPasswordChangedEmailAsync(appUser.Email, appUser.FullName),
            "password-changed",
            appUser.Email);

        return Ok(new { message = "تم تغيير كلمة المرور بنجاح" });
    }

    // PUT: api/AppUsers/ChangePersonalInfo
    [HttpPut("ChangePersonalInfo")]
    public async Task<ActionResult<AppUserDTO>> ChangePersonalInfo(ChangePersonalInfoDTO dto)
    {
        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized();

        var appUser = await _context.AppUsers
            .Where(u => u.Id == userId && u.IsActive)
            .Include(u => u.UserType)
            .Include(u => u.City)
            .FirstOrDefaultAsync();
        if (appUser == null)
            return NotFound();

        var email = dto.Email.Trim();
        if (!string.Equals(appUser.Email, email, StringComparison.OrdinalIgnoreCase) &&
            await _context.AppUsers.AnyAsync(u => u.Email == email && u.Id != userId))
        {
            return BadRequest("البريد الإلكتروني مستخدم بالفعل");
        }

        appUser.FullName = dto.FullName.Trim();
        appUser.Email = email;
        await _context.SaveChangesAsync();

        return Ok(_mapper.Map<AppUserDTO>(appUser));
    }

    // PUT: api/AppUsers/ChangePhoneNumber
    [HttpPut("ChangePhoneNumber")]
    public async Task<ActionResult<AppUserDTO>> ChangePhoneNumber(ChangePhoneNumberDTO dto)
    {
        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized();

        var appUser = await _context.AppUsers
            .Where(u => u.Id == userId && u.IsActive)
            .Include(u => u.UserType)
            .Include(u => u.City)
            .FirstOrDefaultAsync();
        if (appUser == null)
            return NotFound();

        var phone = dto.Phone.Trim();
        var changed = false;

        if (phone != appUser.Phone)
        {
            if (await _context.AppUsers.AnyAsync(u => u.Phone == phone && u.Id != userId))
                return BadRequest("رقم الهاتف مستخدم بالفعل");

            appUser.Phone = phone;
            changed = true;
        }

        if (dto.CityId.HasValue && dto.CityId != appUser.CityId)
        {
            var cityExists = await _context.Cities.AnyAsync(c => c.Id == dto.CityId.Value && c.IsActive);
            if (!cityExists)
                return BadRequest("المدينة غير موجودة أو غير نشطة");

            appUser.CityId = dto.CityId.Value;
            changed = true;
        }

        if (!changed)
            return BadRequest("لا توجد تغييرات للحفظ");

        await _context.SaveChangesAsync();

        return Ok(_mapper.Map<AppUserDTO>(appUser));
    }

    // PATCH: api/AppUsers/UpdateAppUser/{id}
    [HttpPatch("UpdateAppUser/{id}")]
    public async Task<IActionResult>  UpdateAppUser(int id, UpdateAppUserDTO updateAppUserDTO)
    {
        if (!User.IsAdmin() && User.GetUserId() != id)
            return Forbid();

        var appUser = await _context.AppUsers.FindAsync(id);
        if (appUser == null)
        {
            return NotFound();
        }

        // Check if email already exists (if changed)
        if (!string.IsNullOrEmpty(updateAppUserDTO.Email) && updateAppUserDTO.Email != appUser.Email)
        {
            if (await _context.AppUsers.AnyAsync(u => u.Email == updateAppUserDTO.Email))
            {
                return BadRequest("البريد الإلكتروني مستخدم بالفعل");
            }
        }

        // Check if phone already exists (if changed)
        if (!string.IsNullOrEmpty(updateAppUserDTO.Phone) && updateAppUserDTO.Phone != appUser.Phone)
        {
            if (await _context.AppUsers.AnyAsync(u => u.Phone == updateAppUserDTO.Phone))
            {
                return BadRequest("رقم الهاتف مستخدم بالفعل");
            }
        }

        _mapper.Map(updateAppUserDTO, appUser);

        // Update password if provided
        if (!string.IsNullOrEmpty(updateAppUserDTO.Password))
        {
            appUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(updateAppUserDTO.Password);
        }

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!AppUserExists(id))
            {
                return NotFound();
            }
            else
            {
                throw;
            }
        }

        return NoContent();
    }



    // DELETE: api/AppUsers/DeleteAppUser/{id}
    [HttpDelete("DeleteAppUser/{id}")]
    public async Task<IActionResult> DeleteAppUser(int id)
    {
        if (!User.IsAdmin() && User.GetUserId() != id)
            return Forbid();

        var appUser = await _context.AppUsers
            .Include(u => u.UserType)
            .FirstOrDefaultAsync(u => u.Id == id);
        if (appUser == null)
            return NotFound();

        if (string.Equals(appUser.UserType?.Name, AppRoles.Company, StringComparison.OrdinalIgnoreCase))
        {
            if (!User.IsAdmin() && User.GetUserId() == id)
                return BadRequest(new { message = "استخدم حذف حساب الشركة مع تأكيد كلمة المرور." });

            var result = await _companyAccountDeletionService.DeleteCompanyAccountAsync(
                id,
                password: null,
                requirePassword: false,
                HttpContext.RequestAborted);

            return result switch
            {
                CompanyAccountDeletionResult.Success => NoContent(),
                CompanyAccountDeletionResult.ActiveBookingsExist => Conflict(new
                {
                    message = "لا يمكن حذف الحساب لوجود حجوزات نشطة. يُرجى إكمالها أو إلغاؤها أولاً."
                }),
                CompanyAccountDeletionResult.NotCompanyUser => BadRequest(new { message = "نوع المستخدم غير صحيح." }),
                _ => NotFound()
            };
        }

        appUser.IsActive = false;
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // POST: api/AppUsers/DeleteMyCompanyAccount
    [HttpPost("DeleteMyCompanyAccount")]
    [Authorize(Roles = AppRoles.Company)]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteMyCompanyAccount([FromBody] DeleteMyCompanyAccountDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId == null)
            return Unauthorized();

        var result = await _companyAccountDeletionService.DeleteCompanyAccountAsync(
            userId.Value,
            dto.Password,
            requirePassword: true,
            HttpContext.RequestAborted);

        return result switch
        {
            CompanyAccountDeletionResult.Success => NoContent(),
            CompanyAccountDeletionResult.InvalidPassword => BadRequest(new { message = "كلمة المرور غير صحيحة." }),
            CompanyAccountDeletionResult.ActiveBookingsExist => Conflict(new
            {
                message = "لا يمكن حذف الحساب لوجود حجوزات نشطة. يُرجى إكمالها أو إلغاؤها أولاً."
            }),
            CompanyAccountDeletionResult.NotCompanyUser => BadRequest(new { message = "هذا الإجراء متاح لحسابات الشركات فقط." }),
            CompanyAccountDeletionResult.UserNotFound => NotFound(),
            _ => NotFound()
        };
    }

    private bool AppUserExists(int id)
    {
        return _context.AppUsers.Any(e => e.Id == id && e.IsActive);
    }


}


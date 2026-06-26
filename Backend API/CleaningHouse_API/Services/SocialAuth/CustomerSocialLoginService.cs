using AutoMapper;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Services;
using CleaningHouse_API.Services.Email;
using CleaningHouse_API.Services.SocialAuth;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.SocialAuth;

public enum CustomerSocialLoginStatus
{
    Success,
    InvalidProvider,
    InvalidToken,
    EmailRequired,
    EmailConflictWithPasswordAccount,
    EmailAlreadyUsed
}

public sealed class CustomerSocialLoginResult
{
    public CustomerSocialLoginStatus Status { get; init; }
    public LoginResponseDTO? Response { get; init; }
}

public interface ICustomerSocialLoginService
{
    Task<CustomerSocialLoginResult> LoginAsync(
        SocialLoginCustomerDTO dto,
        CancellationToken cancellationToken = default);
}

public class CustomerSocialLoginService : ICustomerSocialLoginService
{
    private readonly ApplicationDbContext _context;
    private readonly ISocialAuthService _socialAuthService;
    private readonly IJwtService _jwtService;
    private readonly IMapper _mapper;
    private readonly ITransactionalEmailQueue _emailQueue;

    public CustomerSocialLoginService(
        ApplicationDbContext context,
        ISocialAuthService socialAuthService,
        IJwtService jwtService,
        IMapper mapper,
        ITransactionalEmailQueue emailQueue)
    {
        _context = context;
        _socialAuthService = socialAuthService;
        _jwtService = jwtService;
        _mapper = mapper;
        _emailQueue = emailQueue;
    }

    public async Task<CustomerSocialLoginResult> LoginAsync(
        SocialLoginCustomerDTO dto,
        CancellationToken cancellationToken = default)
    {
        if (!Enum.IsDefined(typeof(ExternalAuthProvider), dto.Provider))
        {
            return new CustomerSocialLoginResult { Status = CustomerSocialLoginStatus.InvalidProvider };
        }

        var authInfo = await _socialAuthService.ValidateTokenAsync(
            dto.Provider,
            dto.IdToken,
            dto.AccessToken,
            cancellationToken);

        if (authInfo == null || string.IsNullOrWhiteSpace(authInfo.ProviderUserId))
        {
            return new CustomerSocialLoginResult { Status = CustomerSocialLoginStatus.InvalidToken };
        }

        var customerUserType = await _context.UserTypes
            .FirstOrDefaultAsync(ut => ut.Name.ToLower() == "customer", cancellationToken);

        if (customerUserType == null)
        {
            return new CustomerSocialLoginResult { Status = CustomerSocialLoginStatus.InvalidToken };
        }

        var existingExternalLogin = await _context.ExternalLogins
            .Include(e => e.AppUser)!
            .ThenInclude(u => u!.UserType)
            .FirstOrDefaultAsync(
                e => e.Provider == dto.Provider && e.ProviderUserId == authInfo.ProviderUserId,
                cancellationToken);

        if (existingExternalLogin?.AppUser != null)
        {
            return BuildSuccess(existingExternalLogin.AppUser, isNewUser: false);
        }

        var email = authInfo.Email?.Trim();
        AppUser? existingCustomer = null;

        if (!string.IsNullOrWhiteSpace(email))
        {
            existingCustomer = await _context.AppUsers
                .Include(u => u.ExternalLogins)
                .Include(u => u.UserType)
                .FirstOrDefaultAsync(
                    u => u.Email == email && u.UserTypeId == customerUserType.Id && u.IsActive,
                    cancellationToken);
        }

        if (existingCustomer != null)
        {
            var hasExternalLogins = existingCustomer.ExternalLogins?.Count > 0;
            if (!string.IsNullOrWhiteSpace(existingCustomer.PasswordHash) && !hasExternalLogins)
            {
                return new CustomerSocialLoginResult
                {
                    Status = CustomerSocialLoginStatus.EmailConflictWithPasswordAccount
                };
            }

            _context.ExternalLogins.Add(new ExternalLogin
            {
                AppUserId = existingCustomer.Id,
                Provider = dto.Provider,
                ProviderUserId = authInfo.ProviderUserId,
                CreatedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync(cancellationToken);

            return BuildSuccess(existingCustomer, isNewUser: false);
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            return new CustomerSocialLoginResult { Status = CustomerSocialLoginStatus.EmailRequired };
        }

        if (await _context.AppUsers.AnyAsync(u => u.Email == email, cancellationToken))
        {
            return new CustomerSocialLoginResult { Status = CustomerSocialLoginStatus.EmailAlreadyUsed };
        }

        if (!string.IsNullOrWhiteSpace(dto.Phone)
            && await _context.AppUsers.AnyAsync(u => u.Phone == dto.Phone, cancellationToken))
        {
            return new CustomerSocialLoginResult { Status = CustomerSocialLoginStatus.EmailAlreadyUsed };
        }

        var fullName = !string.IsNullOrWhiteSpace(authInfo.FullName)
            ? authInfo.FullName.Trim()
            : !string.IsNullOrWhiteSpace(dto.FullName)
                ? dto.FullName.Trim()
                : email.Split('@')[0];

        var newUser = new AppUser
        {
            FullName = fullName,
            Email = email,
            Phone = string.IsNullOrWhiteSpace(dto.Phone) ? null : dto.Phone.Trim(),
            PasswordHash = null,
            UserTypeId = customerUserType.Id,
            CreatedAt = DateTime.UtcNow
        };

        _context.AppUsers.Add(newUser);
        await _context.SaveChangesAsync(cancellationToken);

        _context.ExternalLogins.Add(new ExternalLogin
        {
            AppUserId = newUser.Id,
            Provider = dto.Provider,
            ProviderUserId = authInfo.ProviderUserId,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync(cancellationToken);

        await _context.Entry(newUser).Reference(u => u.UserType).LoadAsync(cancellationToken);

        _emailQueue.Enqueue(
            sender => sender.SendWelcomeEmailAsync(newUser.Email, newUser.FullName),
            "welcome",
            newUser.Email);

        return BuildSuccess(newUser, isNewUser: true);
    }

    private CustomerSocialLoginResult BuildSuccess(AppUser appUser, bool isNewUser)
    {
        var token = _jwtService.GenerateToken(appUser);
        var userDto = _mapper.Map<AppUserDTO>(appUser);

        return new CustomerSocialLoginResult
        {
            Status = CustomerSocialLoginStatus.Success,
            Response = new LoginResponseDTO
            {
                Success = true,
                Message = isNewUser ? "تم إنشاء الحساب وتسجيل الدخول بنجاح" : "تم تسجيل الدخول بنجاح",
                Token = token,
                User = userDto,
                IsNewUser = isNewUser,
                RequiresProfileCompletion = string.IsNullOrWhiteSpace(appUser.Phone) || !appUser.CityId.HasValue
            }
        };
    }
}

using AutoMapper;
using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Mappings;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Services;
using CleaningHouse_API.Services.Email;
using CleaningHouse_API.Services.SocialAuth;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace CleaningHouse_API.Tests;

public class CustomerSocialLoginServiceTests : IDisposable
{
    private readonly ApplicationDbContext _context;
    private readonly Mock<ISocialAuthService> _socialAuthService = new();
    private readonly Mock<IJwtService> _jwtService = new();
    private readonly Mock<ITransactionalEmailQueue> _emailQueue = new();
    private readonly IMapper _mapper;
    private readonly CustomerSocialLoginService _service;
    private readonly UserType _customerType;

    public CustomerSocialLoginServiceTests()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new ApplicationDbContext(options);
        _customerType = new UserType { Id = 1, Name = "Customer", IsActive = true };
        _context.UserTypes.Add(_customerType);
        _context.SaveChanges();

        _mapper = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>()).CreateMapper();
        _jwtService.Setup(j => j.GenerateToken(It.IsAny<AppUser>())).Returns("test-jwt");

        _service = new CustomerSocialLoginService(
            _context,
            _socialAuthService.Object,
            _jwtService.Object,
            _mapper,
            _emailQueue.Object);
    }

    [Fact]
    public async Task LoginAsync_InvalidToken_ReturnsInvalidToken()
    {
        _socialAuthService
            .Setup(s => s.ValidateTokenAsync(
                ExternalAuthProvider.Google,
                It.IsAny<string?>(),
                It.IsAny<string?>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((SocialAuthUserInfo?)null);

        var result = await _service.LoginAsync(new SocialLoginCustomerDTO
        {
            Provider = ExternalAuthProvider.Google,
            IdToken = "bad-token"
        });

        Assert.Equal(CustomerSocialLoginStatus.InvalidToken, result.Status);
    }

    [Fact]
    public async Task LoginAsync_NewUser_ReturnsJwtAndIsNewUser()
    {
        _socialAuthService
            .Setup(s => s.ValidateTokenAsync(
                ExternalAuthProvider.Google,
                It.IsAny<string?>(),
                It.IsAny<string?>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new SocialAuthUserInfo
            {
                Provider = ExternalAuthProvider.Google,
                ProviderUserId = "google-sub-1",
                Email = "new.customer@example.com",
                FullName = "New Customer"
            });

        var result = await _service.LoginAsync(new SocialLoginCustomerDTO
        {
            Provider = ExternalAuthProvider.Google,
            IdToken = "valid-token"
        });

        Assert.Equal(CustomerSocialLoginStatus.Success, result.Status);
        Assert.NotNull(result.Response);
        Assert.True(result.Response!.IsNewUser);
        Assert.Equal("test-jwt", result.Response.Token);
        Assert.True(result.Response.RequiresProfileCompletion);

        var externalLogin = await _context.ExternalLogins.SingleAsync();
        Assert.Equal("google-sub-1", externalLogin.ProviderUserId);
    }

    [Fact]
    public async Task LoginAsync_ExistingExternalLogin_ReturnsJwtWithoutCreatingUser()
    {
        var user = new AppUser
        {
            FullName = "Existing Social",
            Email = "social@example.com",
            Phone = "0910000001",
            CityId = 1,
            UserTypeId = _customerType.Id,
            CreatedAt = DateTime.UtcNow
        };
        _context.AppUsers.Add(user);
        await _context.SaveChangesAsync();

        _context.ExternalLogins.Add(new ExternalLogin
        {
            AppUserId = user.Id,
            Provider = ExternalAuthProvider.Google,
            ProviderUserId = "google-sub-existing"
        });
        await _context.SaveChangesAsync();

        _socialAuthService
            .Setup(s => s.ValidateTokenAsync(
                ExternalAuthProvider.Google,
                It.IsAny<string?>(),
                It.IsAny<string?>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new SocialAuthUserInfo
            {
                Provider = ExternalAuthProvider.Google,
                ProviderUserId = "google-sub-existing",
                Email = "social@example.com"
            });

        var result = await _service.LoginAsync(new SocialLoginCustomerDTO
        {
            Provider = ExternalAuthProvider.Google,
            IdToken = "valid-token"
        });

        Assert.Equal(CustomerSocialLoginStatus.Success, result.Status);
        Assert.False(result.Response!.IsNewUser);
        Assert.False(result.Response.RequiresProfileCompletion);
        Assert.Equal(1, await _context.AppUsers.CountAsync());
    }

    [Fact]
    public async Task LoginAsync_EmailConflictWithPasswordAccount_ReturnsConflict()
    {
        _context.AppUsers.Add(new AppUser
        {
            FullName = "Password User",
            Email = "conflict@example.com",
            Phone = "0910000002",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("secret123"),
            UserTypeId = _customerType.Id,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();

        _socialAuthService
            .Setup(s => s.ValidateTokenAsync(
                ExternalAuthProvider.Google,
                It.IsAny<string?>(),
                It.IsAny<string?>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new SocialAuthUserInfo
            {
                Provider = ExternalAuthProvider.Google,
                ProviderUserId = "google-sub-new",
                Email = "conflict@example.com"
            });

        var result = await _service.LoginAsync(new SocialLoginCustomerDTO
        {
            Provider = ExternalAuthProvider.Google,
            IdToken = "valid-token"
        });

        Assert.Equal(CustomerSocialLoginStatus.EmailConflictWithPasswordAccount, result.Status);
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}

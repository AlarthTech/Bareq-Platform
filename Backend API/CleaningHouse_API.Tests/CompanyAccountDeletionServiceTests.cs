using CleaningHouse_API.Authentication;
using CleaningHouse_API.Data;
using CleaningHouse_API.Models.Admin;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Models.Companies;
using CleaningHouse_API.Models.Customers;
using CleaningHouse_API.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace CleaningHouse_API.Tests;

public class CompanyAccountDeletionServiceTests : IDisposable
{
    private readonly ApplicationDbContext _context;
    private readonly CompanyAccountDeletionService _service;
    private readonly UserType _companyType;
    private readonly UserType _customerType;
    private readonly City _city;
    private const string TestPassword = "SecurePass1!";

    public CompanyAccountDeletionServiceTests()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new ApplicationDbContext(options);

        _companyType = new UserType { Id = 1, Name = AppRoles.Company, IsActive = true };
        _customerType = new UserType { Id = 2, Name = AppRoles.Customer, IsActive = true };
        _city = new City { Id = 1, Name = "Riyadh", IsActive = true };

        _context.UserTypes.AddRange(_companyType, _customerType);
        _context.Cities.Add(_city);
        _context.SaveChanges();

        var env = new Mock<IWebHostEnvironment>();
        env.Setup(e => e.WebRootPath).Returns(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString()));
        env.Setup(e => e.ContentRootPath).Returns(Directory.GetCurrentDirectory());

        _service = new CompanyAccountDeletionService(
            _context,
            env.Object,
            NullLogger<CompanyAccountDeletionService>.Instance);
    }

    [Fact]
    public async Task DeleteCompanyAccountAsync_WrongPassword_ReturnsInvalidPassword()
    {
        var user = await SeedCompanyOwnerAsync();

        var result = await _service.DeleteCompanyAccountAsync(
            user.Id,
            "wrong-password",
            requirePassword: true);

        Assert.Equal(CompanyAccountDeletionResult.InvalidPassword, result);
        Assert.True((await _context.AppUsers.FindAsync(user.Id))!.IsActive);
    }

    [Fact]
    public async Task DeleteCompanyAccountAsync_ActiveBooking_ReturnsActiveBookingsExist()
    {
        var user = await SeedCompanyOwnerAsync();
        var company = await SeedCompanyAsync(user.Id);
        var worker = await SeedWorkerAsync(company.Id);
        var workType = await SeedWorkTypeAsync(company.Id);
        var customer = await SeedCustomerAsync();
        await SeedBookingAsync(customer.Id, company.Id, worker.Id, workType.Id, BookingStatuses.Pending);

        var result = await _service.DeleteCompanyAccountAsync(
            user.Id,
            TestPassword,
            requirePassword: true);

        Assert.Equal(CompanyAccountDeletionResult.ActiveBookingsExist, result);
        Assert.True((await _context.AppUsers.FindAsync(user.Id))!.IsActive);
    }

    [Fact]
    public async Task DeleteCompanyAccountAsync_CompletedBookingOnly_Succeeds()
    {
        var user = await SeedCompanyOwnerAsync();
        var company = await SeedCompanyAsync(user.Id);
        var worker = await SeedWorkerAsync(company.Id);
        var workType = await SeedWorkTypeAsync(company.Id);
        var customer = await SeedCustomerAsync();
        await SeedBookingAsync(customer.Id, company.Id, worker.Id, workType.Id, BookingStatuses.Completed);

        var result = await _service.DeleteCompanyAccountAsync(
            user.Id,
            TestPassword,
            requirePassword: true);

        Assert.Equal(CompanyAccountDeletionResult.Success, result);
        await AssertSuccessfulDeletionAsync(user.Id, company.Id, worker.Id, workType.Id);
    }

    [Fact]
    public async Task DeleteCompanyAccountAsync_SuccessPath_AnonymizesAndDeactivates()
    {
        var user = await SeedCompanyOwnerAsync();
        var company = await SeedCompanyAsync(user.Id);
        var worker = await SeedWorkerAsync(company.Id);
        var workType = await SeedWorkTypeAsync(company.Id);
        _context.Notifications.Add(new Notification
        {
            UserId = user.Id,
            Title = "Test",
            TitleAr = "اختبار",
            Message = "Message",
            MessageAr = "رسالة",
            NotificationType = NotificationType.BookingCreated
        });
        _context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UserId = user.Id,
            Email = user.Email,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();

        var result = await _service.DeleteCompanyAccountAsync(
            user.Id,
            TestPassword,
            requirePassword: true);

        Assert.Equal(CompanyAccountDeletionResult.Success, result);
        await AssertSuccessfulDeletionAsync(user.Id, company.Id, worker.Id, workType.Id);

        var originalEmail = "owner@company.test";
        Assert.False(await _context.AppUsers.AnyAsync(u => u.Email == originalEmail && u.IsActive));
        Assert.True(await _context.AppUsers.AnyAsync(u => u.Email == $"deleted-user-{user.Id}@internal.deleted"));
    }

    [Fact]
    public async Task DeleteCompanyAccountAsync_NonCompanyUser_ReturnsNotCompanyUser()
    {
        var customer = await SeedCustomerAsync();

        var result = await _service.DeleteCompanyAccountAsync(
            customer.Id,
            TestPassword,
            requirePassword: false);

        Assert.Equal(CompanyAccountDeletionResult.NotCompanyUser, result);
    }

    [Fact]
    public async Task DeleteCompanyAccountAsync_AdminPath_NoPasswordRequired_Succeeds()
    {
        var user = await SeedCompanyOwnerAsync();
        var company = await SeedCompanyAsync(user.Id);

        var result = await _service.DeleteCompanyAccountAsync(
            user.Id,
            password: null,
            requirePassword: false);

        Assert.Equal(CompanyAccountDeletionResult.Success, result);
        await AssertSuccessfulDeletionAsync(user.Id, company.Id);
    }

    private async Task AssertSuccessfulDeletionAsync(
        int userId,
        int companyId,
        int? workerId = null,
        int? workTypeId = null)
    {
        var user = await _context.AppUsers.FindAsync(userId);
        Assert.NotNull(user);
        Assert.False(user.IsActive);
        Assert.NotNull(user.DeletedAt);
        Assert.Null(user.PasswordHash);
        Assert.Null(user.Phone);
        Assert.Equal($"deleted-user-{userId}@internal.deleted", user.Email);

        var company = await _context.Companies.FindAsync(companyId);
        Assert.NotNull(company);
        Assert.False(company.IsActive);
        Assert.False(company.IsVerified);
        Assert.Equal($"deleted-company-{companyId}@internal.deleted", company.Email);

        if (workerId.HasValue)
            Assert.False((await _context.Workers.FindAsync(workerId.Value))!.IsActive);

        if (workTypeId.HasValue)
            Assert.False((await _context.WorkTypes.FindAsync(workTypeId.Value))!.IsActive);

        Assert.False(await _context.Notifications.AnyAsync(n => n.UserId == userId && !n.IsDeleted));
        Assert.False(await _context.PasswordResetTokens.AnyAsync(t => t.UserId == userId));
    }

    private async Task<AppUser> SeedCompanyOwnerAsync()
    {
        var user = new AppUser
        {
            FullName = "Company Owner",
            Email = "owner@company.test",
            Phone = "0500000001",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(TestPassword),
            UserTypeId = _companyType.Id,
            CityId = _city.Id,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        _context.AppUsers.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }

    private async Task<AppUser> SeedCustomerAsync()
    {
        var user = new AppUser
        {
            FullName = "Customer",
            Email = $"customer-{Guid.NewGuid():N}@test.com",
            Phone = $"05{Random.Shared.Next(10000000, 99999999)}",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(TestPassword),
            UserTypeId = _customerType.Id,
            CityId = _city.Id,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
        _context.AppUsers.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }

    private async Task<Company> SeedCompanyAsync(int ownerUserId)
    {
        var company = new Company
        {
            Name = "Test Cleaning Co",
            Email = "company@test.com",
            Phone = "0500000002",
            OwnerUserId = ownerUserId,
            CityId = _city.Id,
            IsActive = true,
            IsVerified = true,
            CreatedAt = DateTime.UtcNow
        };
        _context.Companies.Add(company);
        await _context.SaveChangesAsync();
        return company;
    }

    private async Task<Worker> SeedWorkerAsync(int companyId)
    {
        var worker = new Worker
        {
            CompanyId = companyId,
            FullName = "Worker One",
            NationalityId = 1,
            Age = 30,
            ExperienceYears = 5,
            HealthCertificate = "cert",
            HealthCertificateExpiryDate = DateTime.UtcNow.AddYears(1),
            IsActive = true
        };
        _context.Workers.Add(worker);
        await _context.SaveChangesAsync();
        return worker;
    }

    private async Task<WorkType> SeedWorkTypeAsync(int companyId)
    {
        var workType = new WorkType
        {
            CompanyId = companyId,
            Name = "Daily",
            StartTime = "08:00",
            EndTime = "18:00",
            Price = 100m,
            IsActive = true
        };
        _context.WorkTypes.Add(workType);
        await _context.SaveChangesAsync();
        return workType;
    }

    private async Task<Booking> SeedBookingAsync(
        int customerId,
        int companyId,
        int workerId,
        int workTypeId,
        int status)
    {
        var booking = new Booking
        {
            UserId = customerId,
            CompanyId = companyId,
            WorkerId = workerId,
            WorkTypeId = workTypeId,
            BookingDate = DateTime.UtcNow.AddDays(1),
            StartDate = "08:00",
            EndDate = "18:00",
            Address = "Test address",
            Status = status,
            ServicePrice = 100m,
            PlatformFeeAmount = 10m,
            TotalPrice = 110m,
            CreatedAt = DateTime.UtcNow
        };
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();
        return booking;
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}

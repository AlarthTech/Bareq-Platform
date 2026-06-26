using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Helpers;
using CleaningHouse_API.Models.Common;
using CleaningHouse_API.Services.Email;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services;

public class PasswordResetService : IPasswordResetService
{
    public const string GenericForgotMessage = "إذا كان البريد الإلكتروني مسجلاً لدينا، سيتم إرسال رمز التحقق.";
    public const string InvalidCodeMessage = "رمز التحقق غير صحيح أو منتهي الصلاحية.";
    public const string InvalidResetTokenMessage = "رمز إعادة التعيين غير صالح أو منتهي الصلاحية.";
    public const string SuccessResetMessage = "تم تغيير كلمة المرور بنجاح.";

    private static readonly TimeSpan OtpLifetime = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan ResetTokenLifetime = TimeSpan.FromMinutes(15);
    private const int MaxFailedAttempts = 5;
    private const int MaxOtpRequestsPerEmailPerHour = 5;

    private readonly ApplicationDbContext _context;
    private readonly ITransactionalEmailQueue _emailQueue;
    private readonly ILogger<PasswordResetService> _logger;

    public PasswordResetService(
        ApplicationDbContext context,
        ITransactionalEmailQueue emailQueue,
        ILogger<PasswordResetService> logger)
    {
        _context = context;
        _emailQueue = emailQueue;
        _logger = logger;
    }

    public async Task<ForgotPasswordResponseDto> RequestOtpAsync(
        ForgotPasswordRequestDto request,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken = default)
    {
        var identifier = request.Email.Trim();
        var normalizedEmail = EmailNormalizer.Normalize(identifier);
        var requestedRole = PasswordResetUserType.Normalize(request.UserType);
        var response = new ForgotPasswordResponseDto { Message = GenericForgotMessage };

        var user = await FindActiveUserByIdentifierAndRoleAsync(identifier, normalizedEmail, requestedRole, cancellationToken)
            ?? await FindActiveUserByIdentifierAsync(identifier, normalizedEmail, cancellationToken);

        if (user == null)
        {
            _logger.LogInformation(
                "Forgot password: no active user for role {Role}",
                requestedRole);
            return response;
        }

        var effectiveRole = JwtService.NormalizeRoleName(user.UserType?.Name) ?? requestedRole;

        var hourAgo = DateTime.UtcNow.AddHours(-1);
        var recentCount = await _context.PasswordResetTokens.CountAsync(
            t => t.Email == normalizedEmail && t.CreatedAt >= hourAgo,
            cancellationToken);

        if (recentCount >= MaxOtpRequestsPerEmailPerHour)
        {
            _logger.LogWarning("Forgot password rate limit exceeded for email hash trace");
            return response;
        }

        var otp = ResetTokenGenerator.GenerateSixDigitOtp();
        var now = DateTime.UtcNow;

        var pendingTokens = await _context.PasswordResetTokens
            .Where(t => t.UserId == user.Id && t.UsedAt == null && t.VerifiedAt == null)
            .ToListAsync(cancellationToken);

        foreach (var token in pendingTokens)
            token.UsedAt = now;

        var resetToken = new PasswordResetToken
        {
            UserId = user.Id,
            Email = normalizedEmail,
            CodeHash = SecureHashing.HashSecret(otp),
            CodeExpiresAt = now.Add(OtpLifetime),
            FailedAttempts = 0,
            CreatedAt = now,
            IpAddress = Truncate(ipAddress, 64),
            UserAgent = Truncate(userAgent, 512)
        };

        _context.PasswordResetTokens.Add(resetToken);
        await _context.SaveChangesAsync(cancellationToken);

        if (PasswordResetUserType.IsCompany(effectiveRole))
        {
            _logger.LogInformation(
                "Forgot password: queuing company OTP email for user {UserId}",
                user.Id);
            _emailQueue.Enqueue(
                sender => sender.SendCompanyPasswordResetOtpAsync(user.Email, otp),
                "company-password-reset-otp",
                user.Email);
        }
        else
        {
            _logger.LogInformation(
                "Forgot password: queuing customer OTP email for user {UserId}",
                user.Id);
            _emailQueue.Enqueue(
                sender => sender.SendPasswordResetOtpAsync(user.Email, otp),
                "password-reset-otp",
                user.Email);
        }

        return response;
    }

    public async Task<VerifyResetCodeResponseDto?> VerifyCodeAsync(
        VerifyResetCodeRequestDto request,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = EmailNormalizer.Normalize(request.Email.Trim());
        var code = request.Code.Trim();

        var record = await _context.PasswordResetTokens
            .Where(t => t.Email == normalizedEmail
                && t.UsedAt == null
                && t.VerifiedAt == null
                && t.CodeHash != null)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (record == null || !IsCodeRecordValid(record))
            return null;

        if (record.FailedAttempts >= MaxFailedAttempts)
            return null;

        if (!SecureHashing.VerifySecret(code, record.CodeHash!))
        {
            record.FailedAttempts++;
            await _context.SaveChangesAsync(cancellationToken);
            return null;
        }

        var plainResetToken = ResetTokenGenerator.GenerateResetToken();
        var now = DateTime.UtcNow;

        record.VerifiedAt = now;
        record.ResetTokenHash = SecureHashing.HashSecret(plainResetToken);
        record.ResetTokenExpiresAt = now.Add(ResetTokenLifetime);

        await _context.SaveChangesAsync(cancellationToken);

        return new VerifyResetCodeResponseDto { ResetToken = plainResetToken };
    }

    public async Task<MessageResponseDto?> ResetPasswordAsync(
        ResetPasswordRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (!PasswordPolicyValidator.TryValidate(request.NewPassword, out _))
            return null;

        var normalizedEmail = EmailNormalizer.Normalize(request.Email.Trim());
        var now = DateTime.UtcNow;

        var candidates = await _context.PasswordResetTokens
            .Where(t => t.Email == normalizedEmail
                && t.UsedAt == null
                && t.VerifiedAt != null
                && t.ResetTokenHash != null
                && t.ResetTokenExpiresAt > now)
            .OrderByDescending(t => t.VerifiedAt)
            .ToListAsync(cancellationToken);

        PasswordResetToken? matched = null;
        foreach (var record in candidates)
        {
            if (SecureHashing.VerifySecret(request.ResetToken, record.ResetTokenHash!))
            {
                matched = record;
                break;
            }
        }

        if (matched == null)
            return null;

        var user = await _context.AppUsers
            .Include(u => u.UserType)
            .FirstOrDefaultAsync(u => u.Id == matched.UserId && u.IsActive, cancellationToken);

        if (user == null)
            return null;

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        matched.UsedAt = now;

        var otherTokens = await _context.PasswordResetTokens
            .Where(t => t.UserId == user.Id && t.UsedAt == null && t.Id != matched.Id)
            .ToListAsync(cancellationToken);

        foreach (var token in otherTokens)
            token.UsedAt = now;

        await _context.SaveChangesAsync(cancellationToken);

        _emailQueue.Enqueue(
            sender => sender.SendPasswordChangedEmailAsync(user.Email, user.FullName),
            "password-changed",
            user.Email);

        return new MessageResponseDto { Message = SuccessResetMessage };
    }

    private async Task<AppUser?> FindActiveUserByIdentifierAndRoleAsync(
        string identifier,
        string normalizedEmail,
        string role,
        CancellationToken cancellationToken)
    {
        var roleLower = role.ToLowerInvariant();
        var trimmedPhone = identifier.Trim();

        return await _context.AppUsers
            .AsNoTracking()
            .Include(u => u.UserType)
            .Where(u => u.IsActive
                && u.UserType != null
                && u.UserType.Name.ToLower() == roleLower
                && (u.Email.ToLower() == normalizedEmail || u.Phone == trimmedPhone))
            .FirstOrDefaultAsync(cancellationToken);
    }

    private async Task<AppUser?> FindActiveUserByIdentifierAsync(
        string identifier,
        string normalizedEmail,
        CancellationToken cancellationToken)
    {
        var trimmedPhone = identifier.Trim();

        return await _context.AppUsers
            .AsNoTracking()
            .Include(u => u.UserType)
            .Where(u => u.IsActive
                && u.UserType != null
                && (u.UserType.Name.ToLower() == "customer"
                    || u.UserType.Name.ToLower() == "company"
                    || u.UserType.Name.ToLower() == "companyowner")
                && (u.Email.ToLower() == normalizedEmail || u.Phone == trimmedPhone))
            .FirstOrDefaultAsync(cancellationToken);
    }

    private static bool IsCodeRecordValid(PasswordResetToken record) =>
        record.CodeExpiresAt.HasValue
        && record.CodeExpiresAt.Value > DateTime.UtcNow
        && !string.IsNullOrEmpty(record.CodeHash);

    private static string? Truncate(string? value, int maxLength)
    {
        if (string.IsNullOrEmpty(value))
            return value;
        return value.Length <= maxLength ? value : value[..maxLength];
    }
}

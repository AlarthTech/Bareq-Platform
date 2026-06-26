using System.Text;
using System.Threading.RateLimiting;
using CleaningHouse_API.Configuration;
using CleaningHouse_API.Data;
using CleaningHouse_API.Mappings;
using CleaningHouse_API.Middleware;
using CleaningHouse_API.Services;
using CleaningHouse_API.Services.BookingReports;
using CleaningHouse_API.Services.Bookings;
using CleaningHouse_API.Services.Email;
using CleaningHouse_API.Services.Commission;
using CleaningHouse_API.Services.Notifications;
using CleaningHouse_API.Services.Wallet;
using CleaningHouse_API.Services.Workers;
using CleaningHouse_API.Services.SocialAuth;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

builder.Host.UseSerilog((context, services, configuration) =>
{
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
        .WriteTo.Console();
});

var connectionString =
    builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

if (string.IsNullOrWhiteSpace(connectionString))
    throw new InvalidOperationException(
        "Database connection string is not configured. Set ConnectionStrings__DefaultConnection environment variable.");

builder.Services.AddDbContextPool<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString, sql =>
        sql.EnableRetryOnFailure(maxRetryCount: 3, maxRetryDelay: TimeSpan.FromSeconds(5), errorNumbersToAdd: null)));

builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddSingleton<IUserIdProvider, NotificationUserIdProvider>();
builder.Services.AddAutoMapper(typeof(MappingProfile));
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection(EmailSettings.SectionName));
builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();
builder.Services.AddSingleton<ITransactionalEmailQueue, TransactionalEmailQueue>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<ICompanyAccountDeletionService, CompanyAccountDeletionService>();
builder.Services.AddScoped<IBookingConflictService, BookingConflictService>();
builder.Services.AddScoped<IBookingPricingService, BookingPricingService>();
builder.Services.AddScoped<IPlatformFeeService, PlatformFeeService>();
builder.Services.AddScoped<ICommissionSettingRepository, CommissionSettingRepository>();
builder.Services.AddScoped<IWalletPaymentSettingsRepository, WalletPaymentSettingsRepository>();
builder.Services.AddScoped<IBookingWalletService, BookingWalletService>();
builder.Services.AddScoped<IWalletService, WalletService>();
builder.Services.AddScoped<IWalletCardPaymentGateway, WalletCardPaymentGateway>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IBookingReportRepository, BookingReportRepository>();
builder.Services.AddScoped<IBookingReportService, BookingReportService>();
builder.Services.AddSingleton<INotificationRealtimeSender, SignalRNotificationSender>();
builder.Services.AddScoped<IWorkerHomeService, WorkerHomeService>();
builder.Services.Configure<WalletGatewaySettings>(
    builder.Configuration.GetSection(WalletGatewaySettings.SectionName));
builder.Services.Configure<SocialAuthSettings>(
    builder.Configuration.GetSection(SocialAuthSettings.SectionName));
builder.Services.AddHttpClient();
builder.Services.AddScoped<ISocialTokenValidator, GoogleTokenValidator>();
builder.Services.AddScoped<ISocialTokenValidator, AppleTokenValidator>();
builder.Services.AddScoped<ISocialTokenValidator, FacebookTokenValidator>();
builder.Services.AddScoped<ISocialAuthService, SocialAuthService>();
builder.Services.AddScoped<ICustomerSocialLoginService, CustomerSocialLoginService>();
builder.Services.AddHostedService<BookingAutoCompleteHostedService>();
builder.Services.AddHostedService<HealthCertificateExpiryHostedService>();

builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>("database");

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "CleaningHouse API", Version = "v1" });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

var jwtSecret =
    builder.Configuration["JwtSettings:SecretKey"]
    ?? Environment.GetEnvironmentVariable("JwtSettings__SecretKey")
    ?? string.Empty;

if (jwtSecret.Length < 32)
    throw new InvalidOperationException(
        "JwtSettings:SecretKey must be at least 32 characters. Set JwtSettings__SecretKey environment variable.");

var jwtSection = builder.Configuration.GetSection("JwtSettings");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        ValidateIssuer = true,
        ValidIssuer = jwtSection["Issuer"] ?? "CleaningHouseAPI",
        ValidateAudience = true,
        ValidAudience = jwtSection["Audience"] ?? "CleaningHouseClient",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero,
        RoleClaimType = System.Security.Claims.ClaimTypes.Role
    };
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) &&
                path.StartsWithSegments("/hubs/notifications"))
            {
                context.Token = accessToken;
            }

            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            return RateLimitPartition.GetFixedWindowLimiter("authenticated", _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10_000,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            });
        }

        var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(ip, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 120,
            Window = TimeSpan.FromMinutes(1),
            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
            QueueLimit = 0
        });
    });

    options.AddPolicy("auth", context =>
    {
        var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(ip, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 10,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });

    options.AddPolicy("registration", context =>
    {
        var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(ip, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 5,
            Window = TimeSpan.FromHours(1),
            QueueLimit = 0
        });
    });

    options.AddPolicy("booking-create", context =>
    {
        var key = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anon";
        return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 20,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });

    options.AddPolicy("search", context =>
    {
        var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return RateLimitPartition.GetFixedWindowLimiter(ip, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 60,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
});

var allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("ApiCors", policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
        else if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin()
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
        else
        {
            policy.SetIsOriginAllowed(_ => false);
        }
    });
});

var app = builder.Build();

app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("UserId", httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value);
    };
});

app.UseMiddleware<GlobalExceptionMiddleware>();

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

var enableSwagger = app.Environment.IsDevelopment()
    || builder.Configuration.GetValue<bool>("ServerSettings:EnableSwaggerInProduction");

if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "CleaningHouse API v1");
        c.RoutePrefix = "swagger";
    });
}

if (!app.Environment.IsDevelopment())
    app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseCors("ApiCors");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notifications");
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var payload = new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new { name = e.Key, status = e.Value.Status.ToString() })
        };
        await context.Response.WriteAsJsonAsync(payload);
    }
});

app.Run();

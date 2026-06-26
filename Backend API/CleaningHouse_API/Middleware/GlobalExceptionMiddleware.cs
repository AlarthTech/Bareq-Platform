using System.Net;
using System.Text.Json;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger,
        IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        _logger.LogError(exception, "Unhandled exception for {Method} {Path}",
            context.Request.Method, context.Request.Path);

        if (exception is InsufficientWalletBalanceException insufficient)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsync(JsonSerializer.Serialize(new InsufficientWalletBalanceDTO
            {
                WalletBalance = insufficient.WalletBalance,
                RequiredAmount = insufficient.RequiredAmount
            }));
            return;
        }

        var (statusCode, title, detail) = exception switch
        {
            UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, "Unauthorized", exception.Message),
            KeyNotFoundException => (StatusCodes.Status404NotFound, "Not Found", exception.Message),
            WalletPaymentException => (StatusCodes.Status400BadRequest, "Bad Request", exception.Message),
            ArgumentException arg => (StatusCodes.Status400BadRequest, "Bad Request", arg.Message),
            InvalidOperationException op => (StatusCodes.Status400BadRequest, "Bad Request", op.Message),
            _ => (StatusCodes.Status500InternalServerError, "Internal Server Error",
                _env.IsDevelopment() ? exception.Message : "An unexpected error occurred.")
        };

        var problem = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path
        };

        if (_env.IsDevelopment() && statusCode >= 500)
            problem.Extensions["trace"] = exception.StackTrace;

        context.Response.ContentType = "application/problem+json";
        context.Response.StatusCode = statusCode;
        await context.Response.WriteAsync(JsonSerializer.Serialize(problem));
    }
}

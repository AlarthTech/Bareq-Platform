using CleaningHouse_API.Authentication;
using CleaningHouse_API.Configuration;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CleaningHouse_API.Controllers.Customers;

/// <summary>
/// Test-only wallet helpers. Disabled unless <c>WalletGateway:EnableTestInstantBankCardTopUp</c> is true.
/// </summary>
[ApiController]
[Route("api/v1/wallet/test")]
[Authorize(Roles = AppRoles.Customer)]
public class WalletTestV1Controller : ControllerBase
{
    private readonly IWalletService _walletService;
    private readonly WalletGatewaySettings _gatewaySettings;

    public WalletTestV1Controller(
        IWalletService walletService,
        IOptions<WalletGatewaySettings> gatewaySettings)
    {
        _walletService = walletService;
        _gatewaySettings = gatewaySettings.Value;
    }

    /// <summary>
    /// Instantly credits the customer wallet as if bank card payment succeeded (no gateway / WebView).
    /// </summary>
    [HttpPost("bank-card-charge")]
    [ProducesResponseType(typeof(WalletTopUpCallbackResponseDTO), 200)]
    [ProducesResponseType(404)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpCallbackResponseDTO>> TestInstantBankCardCharge(
        [FromBody] BankCardTopUpRequestDTO dto,
        CancellationToken cancellationToken)
    {
        if (!_gatewaySettings.EnableTestInstantBankCardTopUp)
            return NotFound();

        if (!ValidateTestSecret())
            return Unauthorized(new { message = "Invalid or missing X-Wallet-Test-Secret header." });

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        try
        {
            var result = await _walletService.TestInstantBankCardTopUpAsync(
                userId.Value,
                dto.Amount,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private bool ValidateTestSecret()
    {
        var expected = _gatewaySettings.TestInstantTopUpSecret?.Trim();
        if (string.IsNullOrEmpty(expected))
            return true;

        var provided = Request.Headers["X-Wallet-Test-Secret"].FirstOrDefault()?.Trim();
        return string.Equals(provided, expected, StringComparison.Ordinal);
    }
}

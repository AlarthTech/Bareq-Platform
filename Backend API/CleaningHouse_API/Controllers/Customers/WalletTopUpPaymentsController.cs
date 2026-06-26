using CleaningHouse_API.Configuration;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CleaningHouse_API.Controllers.Customers;

/// <summary>Payment gateway callbacks for wallet top-up (bank card).</summary>
[ApiController]
[Route("api/v1/payments/wallet-top-up")]
public class WalletTopUpPaymentsController : ControllerBase
{
    private readonly IWalletService _walletService;
    private readonly WalletGatewaySettings _gatewaySettings;

    public WalletTopUpPaymentsController(
        IWalletService walletService,
        IOptions<WalletGatewaySettings> gatewaySettings)
    {
        _walletService = walletService;
        _gatewaySettings = gatewaySettings.Value;
    }

    /// <summary>
    /// Gateway webhook after card payment. Credits wallet automatically on success (idempotent).
    /// Send header X-Wallet-Callback-Secret matching WalletGateway:CallbackSecret.
    /// </summary>
    [HttpPost("callback")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(WalletTopUpCallbackResponseDTO), 200)]
    [ProducesResponseType(401)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpCallbackResponseDTO>> Callback(
        [FromBody] WalletTopUpCallbackRequestDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ValidateCallbackSecret())
            return Unauthorized(new { message = "Invalid callback secret." });

        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            return Ok(await _walletService.ProcessWalletTopUpCallbackAsync(dto, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private bool ValidateCallbackSecret()
    {
        if (string.IsNullOrWhiteSpace(_gatewaySettings.CallbackSecret))
            return true;

        if (!Request.Headers.TryGetValue("X-Wallet-Callback-Secret", out var header))
            return false;

        return string.Equals(header.ToString(), _gatewaySettings.CallbackSecret, StringComparison.Ordinal);
    }
}

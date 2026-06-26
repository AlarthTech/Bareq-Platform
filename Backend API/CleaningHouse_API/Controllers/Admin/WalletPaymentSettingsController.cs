using CleaningHouse_API.Authentication;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/payment-settings/wallet")]
[Authorize(Roles = AppRoles.Admin)]
public class WalletPaymentSettingsController : ControllerBase
{
    private readonly IWalletService _walletService;

    public WalletPaymentSettingsController(IWalletService walletService)
    {
        _walletService = walletService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(WalletPaymentSettingsDTO), 200)]
    public async Task<ActionResult<WalletPaymentSettingsDTO>> Get(CancellationToken cancellationToken)
    {
        return Ok(await _walletService.GetPaymentSettingsAsync(cancellationToken));
    }

    [HttpPut]
    [ProducesResponseType(typeof(WalletPaymentSettingsDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletPaymentSettingsDTO>> Put(
        [FromBody] UpdateWalletPaymentSettingsDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminId = User.GetUserId();
        if (adminId is null)
            return Unauthorized();

        try
        {
            return Ok(await _walletService.UpdatePaymentSettingsAsync(dto, adminId.Value, cancellationToken));
        }
        catch (ArgumentOutOfRangeException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

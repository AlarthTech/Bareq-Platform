using CleaningHouse_API.Authentication;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/wallet")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminWalletController : ControllerBase
{
    private readonly IWalletService _walletService;

    public AdminWalletController(IWalletService walletService)
    {
        _walletService = walletService;
    }

    /// <summary>Confirm bank card top-up after payment gateway success (idempotent by payment reference).</summary>
    [HttpPost("top-ups/{id}/confirm-bank-card")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpDTO>> ConfirmBankCardTopUp(
        int id,
        [FromBody] ConfirmBankCardTopUpDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            return Ok(await _walletService.ConfirmBankCardTopUpAsync(id, dto, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("top-ups/{id}/fail-bank-card")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpDTO>> FailBankCardTopUp(
        int id,
        [FromBody] FailBankCardTopUpDTO? dto,
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _walletService.FailBankCardTopUpAsync(id, dto, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("wallets/{customerId}/credit")]
    [ProducesResponseType(typeof(WalletTransactionDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTransactionDTO>> CreditWallet(
        int customerId,
        [FromBody] AdminManualWalletCreditDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminId = User.GetUserId();
        if (adminId is null)
            return Unauthorized();

        try
        {
            return Ok(await _walletService.CreditCustomerWalletAsync(customerId, adminId.Value, dto, cancellationToken));
        }
        catch (ArgumentOutOfRangeException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("wallets/bulk-credit")]
    [ProducesResponseType(typeof(BulkWalletCreditResultDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<BulkWalletCreditResultDTO>> BulkCreditWallets(
        [FromBody] AdminBulkWalletCreditDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminId = User.GetUserId();
        if (adminId is null)
            return Unauthorized();

        try
        {
            return Ok(await _walletService.BulkCreditWalletsAsync(adminId.Value, dto, cancellationToken));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

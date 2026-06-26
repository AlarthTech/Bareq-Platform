using CleaningHouse_API.Authentication;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/wallet/bank-accounts")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminWalletBankAccountsController : ControllerBase
{
    private readonly IWalletService _walletService;

    public AdminWalletBankAccountsController(IWalletService walletService)
    {
        _walletService = walletService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BankTransferAccountDTO>), 200)]
    public async Task<ActionResult<IReadOnlyList<BankTransferAccountDTO>>> GetAll(CancellationToken cancellationToken)
    {
        return Ok(await _walletService.GetBankAccountsAsync(cancellationToken));
    }

    [HttpPost]
    [ProducesResponseType(typeof(BankTransferAccountDTO), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<BankTransferAccountDTO>> Create(
        [FromBody] CreateBankTransferAccountDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var created = await _walletService.CreateBankAccountAsync(dto, cancellationToken);
        return CreatedAtAction(nameof(GetAll), new { id = created.Id }, created);
    }

    [HttpPut("{id}")]
    [ProducesResponseType(typeof(BankTransferAccountDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<BankTransferAccountDTO>> Update(
        int id,
        [FromBody] UpdateBankTransferAccountDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            return Ok(await _walletService.UpdateBankAccountAsync(id, dto, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id}/activate")]
    [ProducesResponseType(typeof(BankTransferAccountDTO), 200)]
    public async Task<ActionResult<BankTransferAccountDTO>> Activate(int id, CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _walletService.ActivateBankAccountAsync(id, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id}/deactivate")]
    [ProducesResponseType(typeof(BankTransferAccountDTO), 200)]
    public async Task<ActionResult<BankTransferAccountDTO>> Deactivate(int id, CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _walletService.DeactivateBankAccountAsync(id, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

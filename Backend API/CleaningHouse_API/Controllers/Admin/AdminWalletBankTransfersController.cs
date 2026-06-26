using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/wallet/top-ups/bank-transfers")]
[Authorize(Roles = AppRoles.Admin)]
public class AdminWalletBankTransfersController : ControllerBase
{
    private readonly IWalletService _walletService;

    public AdminWalletBankTransfersController(IWalletService walletService)
    {
        _walletService = walletService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<WalletTopUpDTO>), 200)]
    public async Task<ActionResult<PagedResult<WalletTopUpDTO>>> GetList(
        [FromQuery] string? status,
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        return Ok(await _walletService.GetBankTransferTopUpsForAdminAsync(status, pagination, cancellationToken));
    }

    [HttpGet("{id}")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<WalletTopUpDTO>> GetById(int id, CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _walletService.GetBankTransferTopUpByIdForAdminAsync(id, cancellationToken));
        }
        catch (InvalidOperationException)
        {
            return NotFound();
        }
    }

    [HttpPost("{id}/approve")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpDTO>> Approve(
        int id,
        [FromBody] ApproveBankTransferTopUpDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminId = User.GetUserId();
        if (adminId is null)
            return Unauthorized();

        try
        {
            return Ok(await _walletService.ApproveBankTransferTopUpAsync(id, adminId.Value, dto, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (ArgumentOutOfRangeException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id}/reject")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpDTO>> Reject(
        int id,
        [FromBody] RejectBankTransferTopUpDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminId = User.GetUserId();
        if (adminId is null)
            return Unauthorized();

        try
        {
            return Ok(await _walletService.RejectBankTransferTopUpAsync(id, adminId.Value, dto, cancellationToken));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

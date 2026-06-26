using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Services.Wallet;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Customers;

[ApiController]
[Route("api/v1/wallet")]
[Authorize(Roles = AppRoles.Customer)]
public class WalletV1Controller : ControllerBase
{
    private readonly IWalletService _walletService;

    public WalletV1Controller(IWalletService walletService)
    {
        _walletService = walletService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(WalletSummaryDTO), 200)]
    public async Task<ActionResult<WalletSummaryDTO>> GetWallet(CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        return Ok(await _walletService.GetWalletSummaryAsync(userId.Value, cancellationToken));
    }

    [HttpGet("transactions")]
    [ProducesResponseType(typeof(PagedResult<WalletTransactionDTO>), 200)]
    public async Task<ActionResult<PagedResult<WalletTransactionDTO>>> GetTransactions(
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        return Ok(await _walletService.GetTransactionsAsync(userId.Value, pagination, cancellationToken));
    }

    [HttpGet("bank-transfer-account")]
    [ProducesResponseType(typeof(BankTransferAccountDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<BankTransferAccountDTO>> GetBankTransferAccount(CancellationToken cancellationToken)
    {
        var account = await _walletService.GetActiveBankTransferAccountForCustomerAsync(cancellationToken);
        if (account == null)
            return NotFound(new { message = "No active bank transfer account is configured." });

        return Ok(account);
    }

    /// <summary>Start bank card wallet top-up — returns payment URL for gateway (no admin approval).</summary>
    [HttpPost("top-up/bank-card")]
    [ProducesResponseType(typeof(BankCardTopUpStartResponseDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<BankCardTopUpStartResponseDTO>> StartBankCardTopUp(
        [FromBody] BankCardTopUpRequestDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        try
        {
            var result = await _walletService.StartBankCardTopUpAsync(userId.Value, dto.Amount, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Bank transfer top-up — pending until admin approval.</summary>
    [HttpPost("top-up")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<WalletTopUpDTO>> CreateBankTransferTopUp(
        [FromBody] CreateWalletTopUpDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        try
        {
            var result = await _walletService.CreateBankTransferTopUpAsync(userId.Value, dto, cancellationToken);
            return CreatedAtAction(nameof(GetTopUp), new { id = result.Id }, result);
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

    [HttpGet("top-ups/{id}")]
    [ProducesResponseType(typeof(WalletTopUpDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<WalletTopUpDTO>> GetTopUp(int id, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var topUp = await _walletService.GetTopUpAsync(userId.Value, id, cancellationToken);
        if (topUp == null)
            return NotFound();

        return Ok(topUp);
    }
}

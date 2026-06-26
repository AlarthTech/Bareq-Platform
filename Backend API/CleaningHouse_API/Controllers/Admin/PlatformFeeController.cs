using CleaningHouse_API.Authentication;
using CleaningHouse_API.DTOs.Admin;
using CleaningHouse_API.Services.Commission;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/platform-fee")]
[Authorize(Roles = AppRoles.Admin)]
public class PlatformFeeController : ControllerBase
{
    private readonly IPlatformFeeService _platformFeeService;

    public PlatformFeeController(IPlatformFeeService platformFeeService)
    {
        _platformFeeService = platformFeeService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PlatformFeeResponseDTO), 200)]
    public async Task<ActionResult<PlatformFeeResponseDTO>> GetPlatformFee(CancellationToken cancellationToken)
    {
        var result = await _platformFeeService.GetCurrentPlatformFeeAsync(cancellationToken);
        return Ok(result);
    }

    [HttpPut]
    [ProducesResponseType(typeof(UpdatePlatformFeeResponseDTO), 200)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<UpdatePlatformFeeResponseDTO>> UpdatePlatformFee(
        [FromBody] UpdatePlatformFeeRequestDTO dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminId = User.GetUserId();
        if (adminId is null)
            return Unauthorized();

        try
        {
            var result = await _platformFeeService.UpdatePlatformFeeAsync(
                dto.ResolveAmount(),
                adminId.Value,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentOutOfRangeException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

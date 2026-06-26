using CleaningHouse_API.Authentication;
using CleaningHouse_API.Core.Pagination;
using CleaningHouse_API.DTOs.Common;
using CleaningHouse_API.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleaningHouse_API.Controllers.Common;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet("GetMyNotifications")]
    [ProducesResponseType(typeof(PagedResult<NotificationDTO>), 200)]
    public async Task<ActionResult<PagedResult<NotificationDTO>>> GetMyNotifications(
        [FromQuery] PaginationParams pagination,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var result = await _notificationService.GetUserNotificationsAsync(userId.Value, pagination, cancellationToken);
        return Ok(result);
    }

    [HttpGet("GetUnreadCount")]
    [ProducesResponseType(typeof(UnreadCountDTO), 200)]
    public async Task<ActionResult<UnreadCountDTO>> GetUnreadCount(CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var count = await _notificationService.GetUnreadCountAsync(userId.Value, cancellationToken);
        return Ok(new UnreadCountDTO { Count = count });
    }

    [HttpGet("GetNotificationById/{id}")]
    [ProducesResponseType(typeof(NotificationDTO), 200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<NotificationDTO>> GetNotificationById(int id, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var notification = await _notificationService.GetNotificationByIdAsync(id, userId.Value, cancellationToken);
        if (notification == null)
            return NotFound();

        return Ok(notification);
    }

    [HttpPatch("MarkAsRead/{id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> MarkAsRead(int id, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var ok = await _notificationService.MarkAsReadAsync(id, userId.Value, cancellationToken);
        if (!ok)
            return NotFound();

        return NoContent();
    }

    [HttpPatch("MarkAllAsRead")]
    [ProducesResponseType(typeof(MarkAllReadResponseDTO), 200)]
    public async Task<ActionResult<MarkAllReadResponseDTO>> MarkAllAsRead(CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var updated = await _notificationService.MarkAllAsReadAsync(userId.Value, cancellationToken);
        return Ok(new MarkAllReadResponseDTO { UpdatedCount = updated });
    }

    [HttpDelete("DeleteNotification/{id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public async Task<IActionResult> DeleteNotification(int id, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        if (userId is null)
            return Unauthorized();

        var ok = await _notificationService.SoftDeleteAsync(id, userId.Value, cancellationToken);
        if (!ok)
            return NotFound();

        return NoContent();
    }
}

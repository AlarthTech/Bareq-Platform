using CleaningHouse_API.Models.Common;

namespace CleaningHouse_API.DTOs.Common;

public class NotificationDTO
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string TitleAr { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string MessageAr { get; set; } = string.Empty;
    public NotificationType NotificationType { get; set; }
    public string NotificationTypeName { get; set; } = string.Empty;
    public int? RelatedEntityId { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UnreadCountDTO
{
    public int Count { get; set; }
}

public class MarkAllReadResponseDTO
{
    public int UpdatedCount { get; set; }
    public string Message { get; set; } = "تم تعليم جميع الإشعارات كمقروءة.";
}

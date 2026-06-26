/// User-controllable in-app notification groups.
enum NotificationCategory {
  bookingStatus,
  promotional,
  general,
}

/// Maps API [notificationType] values to a preference category.
NotificationCategory notificationCategoryForType(int notificationType) {
  if (notificationType >= 1 && notificationType <= 5) {
    return NotificationCategory.bookingStatus;
  }
  if (notificationType == 6) {
    return NotificationCategory.promotional;
  }
  return NotificationCategory.general;
}

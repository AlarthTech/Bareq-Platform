enum NotificationDateSection {
  today,
  yesterday,
  earlier,
}

class NotificationDateGrouper {
  NotificationDateGrouper._();

  static NotificationDateSection sectionFor(DateTime createdAt) {
    final now = DateTime.now();
    final local = createdAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(createdDay).inDays;

    if (diff == 0) return NotificationDateSection.today;
    if (diff == 1) return NotificationDateSection.yesterday;
    return NotificationDateSection.earlier;
  }

  static String sectionLabel(NotificationDateSection section) {
    return switch (section) {
      NotificationDateSection.today => 'اليوم',
      NotificationDateSection.yesterday => 'أمس',
      NotificationDateSection.earlier => 'سابقاً',
    };
  }
}

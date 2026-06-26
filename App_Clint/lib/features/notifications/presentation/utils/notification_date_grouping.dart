enum NotificationDateGroup { today, yesterday, earlier }

NotificationDateGroup notificationDateGroupFor(DateTime createdAt) {
  final now = DateTime.now();
  final local = createdAt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final createdDay = DateTime(local.year, local.month, local.day);
  final diff = today.difference(createdDay).inDays;

  if (diff == 0) return NotificationDateGroup.today;
  if (diff == 1) return NotificationDateGroup.yesterday;
  return NotificationDateGroup.earlier;
}

String notificationDateGroupLabel(
  NotificationDateGroup group,
  String Function(String key) translate,
) {
  switch (group) {
    case NotificationDateGroup.today:
      return translate('today');
    case NotificationDateGroup.yesterday:
      return translate('yesterday');
    case NotificationDateGroup.earlier:
      return translate('earlier');
  }
}

Map<NotificationDateGroup, List<T>> groupNotificationsByDate<T>(
  List<T> items,
  DateTime Function(T item) createdAtSelector,
) {
  final map = <NotificationDateGroup, List<T>>{
    NotificationDateGroup.today: [],
    NotificationDateGroup.yesterday: [],
    NotificationDateGroup.earlier: [],
  };

  for (final item in items) {
    final group = notificationDateGroupFor(createdAtSelector(item));
    map[group]!.add(item);
  }

  return map;
}

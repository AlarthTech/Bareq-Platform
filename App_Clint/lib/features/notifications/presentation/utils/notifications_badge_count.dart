import '../state/notifications_state.dart';

extension NotificationsStateBadge on NotificationsState {
  /// Unread count for the launcher badge, or null before notifications load.
  int? get launcherBadgeUnreadCount => switch (this) {
        NotificationsInitial() => null,
        NotificationsLoaded(:final unreadCount) => unreadCount,
        NotificationsListError(:final unreadCount) => unreadCount,
      };
}

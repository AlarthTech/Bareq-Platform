import 'package:equatable/equatable.dart';

import 'notification_category.dart';

/// Local notification preference (device storage).
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.notificationsEnabled = true,
  });

  /// When false, all in-app notification alerts are suppressed.
  final bool notificationsEnabled;

  static const NotificationPreferences defaults = NotificationPreferences();

  bool isEnabled(NotificationCategory category) => notificationsEnabled;

  NotificationPreferences copyWith({bool? notificationsEnabled}) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [notificationsEnabled];
}

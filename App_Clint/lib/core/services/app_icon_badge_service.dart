import 'package:app_badge_plus/app_badge_plus.dart';

/// Syncs unread in-app notification count to the launcher app icon badge.
class AppIconBadgeService {
  Future<void> updateUnreadCount(int count) async {
    final badge = count < 0 ? 0 : count;
    try {
      if (!await AppBadgePlus.isSupported()) return;
      await AppBadgePlus.updateBadge(badge);
    } catch (_) {
      // Best-effort; unsupported launchers or permission denied.
    }
  }

  Future<void> clear() => updateUnreadCount(0);
}

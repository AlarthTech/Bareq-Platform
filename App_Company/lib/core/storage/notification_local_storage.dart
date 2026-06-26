import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/models/notification_model.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';

class NotificationLocalStorage {
  NotificationLocalStorage._();

  static const _notificationsKey = 'cached_notifications';
  static const _unreadKey = 'cached_unread_count';

  static Future<void> saveNotifications(List<NotificationEntity> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items
        .map(
          (n) => {
            'id': n.id,
            'title': n.title,
            'message': n.message,
            'titleAr': n.titleAr,
            'messageAr': n.messageAr,
            'notificationTypeId': n.notificationTypeId,
            'notificationTypeName': n.notificationTypeName,
            'relatedEntityId': n.relatedEntityId,
            'isRead': n.isRead,
            'createdAt': n.createdAt.toIso8601String(),
          },
        )
        .toList();
    await prefs.setString(_notificationsKey, jsonEncode(encoded));
  }

  static Future<List<NotificationEntity>> readNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => NotificationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ).toEntity(),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveUnreadCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unreadKey, count);
  }

  static Future<int> readUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unreadKey) ?? 0;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    await prefs.remove(_unreadKey);
  }
}

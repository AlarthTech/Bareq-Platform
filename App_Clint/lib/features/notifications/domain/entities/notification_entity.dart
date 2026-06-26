import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'notification_category.dart';
import 'notification_preferences.dart';

/// In-app notification (domain layer).
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.message,
    required this.messageAr,
    required this.notificationType,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String titleAr;
  final String message;
  final String messageAr;
  final int notificationType;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  String localizedTitle(Locale locale) =>
      locale.languageCode == 'ar' && titleAr.trim().isNotEmpty
          ? titleAr
          : title;

  String localizedMessage(Locale locale) =>
      locale.languageCode == 'ar' && messageAr.trim().isNotEmpty
          ? messageAr
          : message;

  bool get isBookingNotification =>
      relatedEntityId != null &&
      notificationType >= 1 &&
      notificationType <= 5;

  static const int bookingReportStatusUpdated = 22;

  bool get isBookingReportStatusUpdated =>
      notificationType == bookingReportStatusUpdated &&
      relatedEntityId != null;

  NotificationCategory get category =>
      notificationCategoryForType(notificationType);

  bool isAllowedBy(NotificationPreferences preferences) =>
      preferences.isEnabled(category);

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      titleAr: titleAr,
      message: message,
      messageAr: messageAr,
      notificationType: notificationType,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        titleAr,
        message,
        messageAr,
        notificationType,
        relatedEntityId,
        isRead,
        createdAt,
      ];
}

class NotificationRealtimeUpdate extends Equatable {
  const NotificationRealtimeUpdate({
    required this.notification,
    required this.unreadCount,
  });

  final NotificationEntity notification;
  final int unreadCount;

  @override
  List<Object?> get props => [notification, unreadCount];
}

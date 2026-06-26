import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    this.titleAr,
    this.messageAr,
    this.notificationTypeId,
    this.notificationTypeName,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String? titleAr;
  final String? messageAr;
  final int? notificationTypeId;
  final String? notificationTypeName;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  String localizedTitle(bool isArabic) {
    if (isArabic && titleAr != null && titleAr!.trim().isNotEmpty) {
      return titleAr!.trim();
    }
    return title;
  }

  String localizedMessage(bool isArabic) {
    if (isArabic && messageAr != null && messageAr!.trim().isNotEmpty) {
      return messageAr!.trim();
    }
    return message;
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      message: message,
      titleAr: titleAr,
      messageAr: messageAr,
      notificationTypeId: notificationTypeId,
      notificationTypeName: notificationTypeName,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        titleAr,
        messageAr,
        notificationTypeId,
        notificationTypeName,
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

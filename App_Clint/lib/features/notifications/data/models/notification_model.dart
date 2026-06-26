import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.userId,
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
  final int userId;
  final String title;
  final String titleAr;
  final String message;
  final String messageAr;
  final int notificationType;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _int(json['id']) ?? 0,
      userId: _int(json['userId']) ?? 0,
      title: json['title']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      messageAr: json['messageAr']?.toString() ?? '',
      notificationType: _int(json['notificationType']) ?? 0,
      relatedEntityId: _int(json['relatedEntityId']),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        title: title,
        titleAr: titleAr,
        message: message,
        messageAr: messageAr,
        notificationType: notificationType,
        relatedEntityId: relatedEntityId,
        isRead: isRead,
        createdAt: createdAt,
      );

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class UnreadCountModel {
  UnreadCountModel({required this.count});

  final int count;

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) {
    return UnreadCountModel(count: NotificationModel._int(json['count']) ?? 0);
  }
}

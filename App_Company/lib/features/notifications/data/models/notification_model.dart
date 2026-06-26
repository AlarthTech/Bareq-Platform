import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    super.titleAr,
    super.messageAr,
    super.notificationTypeId,
    super.notificationTypeName,
    super.relatedEntityId,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _asInt(json['id']),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      titleAr: json['titleAr'] as String?,
      messageAr: json['messageAr'] as String?,
      notificationTypeId: _asIntOrNull(json['notificationTypeId']),
      notificationTypeName: json['notificationTypeName'] as String?,
      relatedEntityId: _asIntOrNull(json['relatedEntityId']),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        title: title,
        message: message,
        titleAr: titleAr,
        messageAr: messageAr,
        notificationTypeId: notificationTypeId,
        notificationTypeName: notificationTypeName,
        relatedEntityId: relatedEntityId,
        isRead: isRead,
        createdAt: createdAt,
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateFormatter.parseDate(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

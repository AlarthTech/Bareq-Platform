import '../../../../core/utils/booking_status_mapper.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_status_changed_event.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

class RealtimePayloadMapper {
  RealtimePayloadMapper._();

  static NotificationEntity? notificationFromMap(Map<String, dynamic> json) {
    try {
      if (json.containsKey('notificationTypeName') ||
          json.containsKey('notificationTypeId')) {
        return NotificationModel.fromJson(json).toEntity();
      }

      final bookingId = _asIntOrNull(json['bookingId'] ?? json['relatedEntityId']);
      final statusRaw = json['status']?.toString();
      final status = BookingStatusMapper.fromString(statusRaw);

      return NotificationEntity(
        id: _asInt(json['id']),
        title: json['title'] as String? ?? 'تحديث الحجز',
        message: json['message'] as String? ?? '',
        titleAr: json['titleAr'] as String?,
        messageAr: json['messageAr'] as String?,
        notificationTypeName: _bookingTypeFromStatus(statusRaw),
        relatedEntityId: bookingId,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: _parseDate(json['createdAt']),
      );
    } catch (_) {
      return null;
    }
  }

  static BookingStatusChangedEvent? bookingStatusFromMap(
    Map<String, dynamic> json,
  ) {
    try {
      final bookingId = _asIntOrNull(json['bookingId'] ?? json['relatedEntityId']);
      if (bookingId == null) return null;

      final statusRaw = json['status']?.toString();
      final status = BookingStatusMapper.fromString(statusRaw);
      if (status == null) return null;

      return BookingStatusChangedEvent(
        notificationId: _asIntOrNull(json['id']),
        bookingId: bookingId,
        status: status,
        statusName: statusRaw,
        title: json['title'] as String? ?? 'تحديث الحجز',
        message: json['message'] as String? ?? '',
        createdAt: _parseDate(json['createdAt']),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _bookingTypeFromStatus(String? status) {
    if (status == null) return 'BookingUpdated';
    final normalized = status.replaceAll(' ', '');
    if (normalized.toLowerCase().startsWith('booking')) return normalized;
    return 'Booking$normalized';
  }

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

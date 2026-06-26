import 'package:equatable/equatable.dart';

import 'booking_status_codes.dart';

/// Real-time booking status payload from SignalR `BookingStatusChanged`.
class BookingStatusChangedEvent extends Equatable {
  const BookingStatusChangedEvent({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.bookingId,
    required this.statusCode,
    this.statusLabel,
    required this.createdAt,
  });

  final int notificationId;
  final String title;
  final String message;
  final int bookingId;
  final int statusCode;
  final String? statusLabel;
  final DateTime createdAt;

  factory BookingStatusChangedEvent.fromHubPayload(Map<String, dynamic> json) {
    final statusLabel = json['status']?.toString();
    final statusCode =
        BookingStatusCodes.fromApiLabel(statusLabel) ??
        BookingStatusCodes.fromApiLabel(json['statusCode']?.toString()) ??
        BookingStatusCodes.pending;

    return BookingStatusChangedEvent(
      notificationId: _int(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      bookingId: _int(json['bookingId']) ?? 0,
      statusCode: statusCode,
      statusLabel: statusLabel,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        notificationId,
        title,
        message,
        bookingId,
        statusCode,
        statusLabel,
        createdAt,
      ];
}

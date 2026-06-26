import 'package:equatable/equatable.dart';

class BookingStatusChangedEvent extends Equatable {
  const BookingStatusChangedEvent({
    this.notificationId,
    required this.bookingId,
    required this.status,
    this.statusName,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final int? notificationId;
  final int bookingId;
  final int status;
  final String? statusName;
  final String title;
  final String message;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        notificationId,
        bookingId,
        status,
        statusName,
        title,
        message,
        createdAt,
      ];
}

import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  
  @override
  List<Object?> get props => [];
}

class GetBookingsEvent extends BookingEvent {
  final int companyId;

  const GetBookingsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadMoreBookingsEvent extends BookingEvent {
  final int companyId;

  const LoadMoreBookingsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class UpdateBookingStatusEvent extends BookingEvent {
  final int bookingId;
  final int statusValue;
  final String? rejectionReason;

  const UpdateBookingStatusEvent({
    required this.bookingId,
    required this.statusValue,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [bookingId, statusValue, rejectionReason];
}

class BookingStatusChangedRealtimeEvent extends BookingEvent {
  const BookingStatusChangedRealtimeEvent({
    required this.bookingId,
    required this.status,
  });

  final int bookingId;
  final int status;

  @override
  List<Object?> get props => [bookingId, status];
}

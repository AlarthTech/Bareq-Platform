import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_status_changed_event.dart';

class BookingRealtimeState extends Equatable {
  const BookingRealtimeState({
    this.latest,
    this.statusByBookingId = const {},
  });

  final BookingStatusChangedEvent? latest;
  final Map<int, int> statusByBookingId;

  BookingRealtimeState copyWith({
    BookingStatusChangedEvent? latest,
    Map<int, int>? statusByBookingId,
  }) {
    return BookingRealtimeState(
      latest: latest ?? this.latest,
      statusByBookingId: statusByBookingId ?? this.statusByBookingId,
    );
  }

  @override
  List<Object?> get props => [latest, statusByBookingId];
}

/// Broadcasts live booking status changes from SignalR to open screens.
class BookingRealtimeCubit extends Cubit<BookingRealtimeState> {
  BookingRealtimeCubit() : super(const BookingRealtimeState());

  void applyStatusChange(BookingStatusChangedEvent event) {
    if (event.bookingId <= 0) return;
    emit(
      BookingRealtimeState(
        latest: event,
        statusByBookingId: {
          ...state.statusByBookingId,
          event.bookingId: event.statusCode,
        },
      ),
    );
  }

  void reset() => emit(const BookingRealtimeState());
}

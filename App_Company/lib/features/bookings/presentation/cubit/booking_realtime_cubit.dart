import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notifications/domain/entities/booking_status_changed_event.dart';
import '../../domain/usecases/get_booking_by_id_usecase.dart';

class BookingRealtimeState {
  const BookingRealtimeState({this.lastEvent});

  final BookingStatusChangedEvent? lastEvent;

  BookingRealtimeState copyWith({BookingStatusChangedEvent? lastEvent}) {
    return BookingRealtimeState(lastEvent: lastEvent ?? this.lastEvent);
  }
}

/// App-level hub for booking status changes delivered via SignalR.
class BookingRealtimeCubit extends Cubit<BookingRealtimeState> {
  BookingRealtimeCubit({
    required GetBookingByIdUseCase getBookingByIdUseCase,
  })  : _getBookingByIdUseCase = getBookingByIdUseCase,
        super(const BookingRealtimeState());

  final GetBookingByIdUseCase _getBookingByIdUseCase;

  void onBookingStatusChanged(BookingStatusChangedEvent event) {
    emit(BookingRealtimeState(lastEvent: event));
  }

  Future<void> fetchFreshBooking(int bookingId) async {
    await _getBookingByIdUseCase(bookingId);
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/get_booking_by_id_usecase.dart';

class BookingDetailState extends Equatable {
  final BookingEntity booking;
  final bool isRefreshing;
  final String? errorMessage;

  const BookingDetailState({
    required this.booking,
    this.isRefreshing = false,
    this.errorMessage,
  });

  BookingDetailState copyWith({
    BookingEntity? booking,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookingDetailState(
      booking: booking ?? this.booking,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [booking, isRefreshing, errorMessage];
}

class BookingDetailCubit extends Cubit<BookingDetailState> {
  BookingDetailCubit({
    required GetBookingByIdUseCase getBookingByIdUseCase,
    required BookingEntity initialBooking,
  })  : _getBookingByIdUseCase = getBookingByIdUseCase,
        super(BookingDetailState(booking: initialBooking));

  final GetBookingByIdUseCase _getBookingByIdUseCase;

  Future<void> refreshFromApi() async {
    final id = state.booking.id;
    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _getBookingByIdUseCase(id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: failure.message,
        ),
      ),
      (booking) => emit(
        BookingDetailState(booking: booking, isRefreshing: false),
      ),
    );
  }

  void applyBooking(BookingEntity booking) {
    if (booking.id != state.booking.id) return;
    emit(state.copyWith(booking: booking, clearError: true));
  }

  void applyStatusChange(int status) {
    emit(
      state.copyWith(
        booking: state.booking.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        ),
        clearError: true,
      ),
    );
    refreshFromApi();
  }
}

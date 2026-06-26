import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_bookings_usecase.dart';
import '../../domain/usecases/update_booking_status_usecase.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GetBookingsUseCase getBookingsUseCase;
  final UpdateBookingStatusUseCase updateBookingStatusUseCase;

  int? _lastCompanyId;
  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;

  BookingBloc({
    required this.getBookingsUseCase,
    required this.updateBookingStatusUseCase,
  }) : super(const BookingInitial()) {
    on<GetBookingsEvent>(_onGetBookings);
    on<LoadMoreBookingsEvent>(_onLoadMoreBookings);
    on<UpdateBookingStatusEvent>(_onUpdateBookingStatus);
    on<BookingStatusChangedRealtimeEvent>(_onBookingStatusChangedRealtime);
  }

  Future<void> _onGetBookings(
    GetBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    _lastCompanyId = event.companyId;
    _currentPage = 1;
    emit(const BookingLoading());

    final result = await getBookingsUseCase(
      GetBookingsParams(companyId: event.companyId),
    );

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (page) {
        _hasNextPage = page.hasNextPage;
        _currentPage = page.page;
        emit(
          BookingsLoaded(
            bookings: page.items,
            hasNextPage: page.hasNextPage,
            totalCount: page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreBookings(
    LoadMoreBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (!_hasNextPage || _isLoadingMore) return;
    final current = state;
    if (current is! BookingsLoaded) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));

    final nextPage = _currentPage + 1;
    final result = await getBookingsUseCase(
      GetBookingsParams(
        companyId: event.companyId,
        pagination: PaginationParams(page: nextPage),
      ),
    );

    _isLoadingMore = false;

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (page) {
        _hasNextPage = page.hasNextPage;
        _currentPage = page.page;
        emit(
          BookingsLoaded(
            bookings: [...current.bookings, ...page.items],
            hasNextPage: page.hasNextPage,
            totalCount: page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatusEvent event,
    Emitter<BookingState> emit,
  ) async {
    final result = await updateBookingStatusUseCase(
      UpdateBookingStatusParams(
        bookingId: event.bookingId,
        statusValue: event.statusValue,
        rejectionReason: event.rejectionReason,
      ),
    );

    await result.fold(
      (failure) async => emit(BookingError(failure.message)),
      (_) async {
        final companyId = _lastCompanyId;
        if (companyId == null) {
          emit(BookingStatusUpdated(event.bookingId));
          return;
        }
        add(GetBookingsEvent(companyId));
      },
    );
  }

  void _onBookingStatusChangedRealtime(
    BookingStatusChangedRealtimeEvent event,
    Emitter<BookingState> emit,
  ) {
    final current = state;
    if (current is! BookingsLoaded) return;

    final index =
        current.bookings.indexWhere((b) => b.id == event.bookingId);
    if (index < 0) return;

    final updated = List.of(current.bookings);
    updated[index] = updated[index].copyWith(
      status: event.status,
      updatedAt: DateTime.now(),
    );

    emit(
      current.copyWith(bookings: updated),
    );
  }
}

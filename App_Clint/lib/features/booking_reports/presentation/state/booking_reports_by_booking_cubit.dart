import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/usecases/get_booking_reports_by_booking_usecase.dart';
import 'booking_reports_by_booking_state.dart';

class BookingReportsByBookingCubit extends Cubit<BookingReportsByBookingState> {
  BookingReportsByBookingCubit({
    required GetBookingReportsByBookingUseCase getBookingReportsByBookingUseCase,
    required int bookingId,
  })  : _getBookingReportsByBookingUseCase =
            getBookingReportsByBookingUseCase,
        _bookingId = bookingId,
        super(const BookingReportsByBookingInitial());

  final GetBookingReportsByBookingUseCase _getBookingReportsByBookingUseCase;
  final int _bookingId;

  Future<void> loadFirstPage() =>
      _load(page: PaginationConstants.defaultPage, reset: true);

  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! BookingReportsByBookingLoaded ||
        !current.hasNextPage ||
        current.isLoadingMore) {
      return;
    }
    await _load(page: current.page + 1, reset: false);
  }

  Future<void> _load({required int page, required bool reset}) async {
    if (isClosed) return;

    final current = state;
    if (reset) {
      emit(const BookingReportsByBookingLoading());
    } else if (current is BookingReportsByBookingLoaded) {
      emit(current.copyWith(isLoadingMore: true));
    }

    final result = await _getBookingReportsByBookingUseCase(
      bookingId: _bookingId,
      page: page,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        if (reset || current is! BookingReportsByBookingLoaded) {
          emit(BookingReportsByBookingError(_mapFailure(failure)));
        } else {
          emit(current.copyWith(isLoadingMore: false));
        }
      },
      (pageResult) {
        final previous =
            (!reset && current is BookingReportsByBookingLoaded)
                ? current.reports
                : <BookingReport>[];
        emit(
          BookingReportsByBookingLoaded(
            reports:
                reset
                    ? pageResult.items
                    : [...previous, ...pageResult.items],
            hasNextPage: pageResult.hasNextPage,
            page: pageResult.page,
          ),
        );
      },
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is AuthFailure) return failure.message;
    if (failure is ForbiddenFailure) return failure.message;
    if (failure is NetworkFailure) {
      return 'خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }
    return failure.message;
  }
}

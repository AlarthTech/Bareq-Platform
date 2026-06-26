import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/usecases/get_my_booking_reports_usecase.dart';
import 'my_booking_reports_state.dart';

class MyBookingReportsCubit extends Cubit<MyBookingReportsState> {
  MyBookingReportsCubit(this._getMyBookingReportsUseCase)
      : super(const MyBookingReportsInitial());

  final GetMyBookingReportsUseCase _getMyBookingReportsUseCase;

  Future<void> loadFirstPage() =>
      _load(page: PaginationConstants.defaultPage, reset: true);

  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! MyBookingReportsLoaded ||
        !current.hasNextPage ||
        current.isLoadingMore) {
      return;
    }
    await _load(page: current.page + 1, reset: false);
  }

  BookingReport? findInCache(int reportId) {
    final current = state;
    if (current is! MyBookingReportsLoaded) return null;
    for (final report in current.reports) {
      if (report.id == reportId) return report;
    }
    return null;
  }

  Future<void> _load({required int page, required bool reset}) async {
    if (isClosed) return;

    final current = state;
    if (reset) {
      emit(const MyBookingReportsLoading());
    } else if (current is MyBookingReportsLoaded) {
      emit(current.copyWith(isLoadingMore: true));
    }

    final result = await _getMyBookingReportsUseCase(page: page);
    if (isClosed) return;

    result.fold(
      (failure) {
        if (reset || current is! MyBookingReportsLoaded) {
          emit(MyBookingReportsError(_mapFailure(failure)));
        } else {
          emit(current.copyWith(isLoadingMore: false));
        }
      },
      (pageResult) {
        final previous =
            (!reset && current is MyBookingReportsLoaded)
                ? current.reports
                : <BookingReport>[];
        emit(
          MyBookingReportsLoaded(
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

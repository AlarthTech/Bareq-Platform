import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/get_my_reports_usecase.dart';
import 'my_reports_state.dart';

class MyReportsCubit extends Cubit<MyReportsState> {
  MyReportsCubit(this._getMyReportsUseCase) : super(const MyReportsInitial());

  final GetMyReportsUseCase _getMyReportsUseCase;

  Future<void> loadFirstPage() => _load(page: PaginationConstants.defaultPage, reset: true);

  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! MyReportsLoaded ||
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
      emit(const MyReportsLoading());
    } else if (current is MyReportsLoaded) {
      emit(current.copyWith(isLoadingMore: true));
    }

    final result = await _getMyReportsUseCase(page: page);
    if (isClosed) return;

    result.fold(
      (failure) {
        if (reset || current is! MyReportsLoaded) {
          emit(MyReportsError(_mapFailure(failure)));
        } else {
          emit(current.copyWith(isLoadingMore: false));
        }
      },
      (pageResult) {
        final previous =
            (!reset && current is MyReportsLoaded)
                ? current.reports
                : <Report>[];
        final merged =
            reset
                ? pageResult.items
                : [...previous, ...pageResult.items];
        emit(
          MyReportsLoaded(
            reports: merged,
            hasNextPage: pageResult.hasNextPage,
            page: pageResult.page,
          ),
        );
      },
    );
  }

  void removeReportLocally(int id) {
    final current = state;
    if (current is! MyReportsLoaded) return;
    emit(
      current.copyWith(
        reports: current.reports.where((r) => r.id != id).toList(),
      ),
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

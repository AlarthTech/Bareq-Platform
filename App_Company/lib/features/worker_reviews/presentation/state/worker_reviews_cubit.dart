import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_worker_rating_summary.dart';
import '../../domain/usecases/get_worker_reviews.dart';
import 'worker_reviews_state.dart';

class WorkerReviewsCubit extends Cubit<WorkerReviewsState> {
  WorkerReviewsCubit({
    required GetWorkerRatingSummaryUseCase getWorkerRatingSummaryUseCase,
    required GetWorkerReviewsUseCase getWorkerReviewsUseCase,
  })  : _getWorkerRatingSummaryUseCase = getWorkerRatingSummaryUseCase,
        _getWorkerReviewsUseCase = getWorkerReviewsUseCase,
        super(const WorkerReviewsInitial());

  final GetWorkerRatingSummaryUseCase _getWorkerRatingSummaryUseCase;
  final GetWorkerReviewsUseCase _getWorkerReviewsUseCase;

  static const _pageSize = 20;

  Future<void> load(int workerId) async {
    emit(const WorkerReviewsLoading());

    final summaryResult = await _getWorkerRatingSummaryUseCase(workerId);
    final reviewsResult = await _getWorkerReviewsUseCase(
      GetWorkerReviewsParams(workerId: workerId, page: 1, pageSize: _pageSize),
    );

    summaryResult.fold(
      (failure) => emit(WorkerReviewsError(failure.message)),
      (summary) {
        reviewsResult.fold(
          (failure) => emit(WorkerReviewsError(failure.message)),
          (page) => emit(
            WorkerReviewsLoaded(
              summary: summary,
              reviews: page.items,
              currentPage: page.page,
              hasNextPage: page.hasNextPage,
            ),
          ),
        );
      },
    );
  }

  Future<void> refresh(int workerId) async {
    final current = state;
    if (current is WorkerReviewsLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }

    final summaryResult = await _getWorkerRatingSummaryUseCase(workerId);
    final reviewsResult = await _getWorkerReviewsUseCase(
      GetWorkerReviewsParams(workerId: workerId, page: 1, pageSize: _pageSize),
    );

    summaryResult.fold(
      (failure) => emit(WorkerReviewsError(failure.message)),
      (summary) {
        reviewsResult.fold(
          (failure) => emit(WorkerReviewsError(failure.message)),
          (page) => emit(
            WorkerReviewsLoaded(
              summary: summary,
              reviews: page.items,
              currentPage: page.page,
              hasNextPage: page.hasNextPage,
            ),
          ),
        );
      },
    );
  }

  Future<void> loadNextPage(int workerId) async {
    final current = state;
    if (current is! WorkerReviewsLoaded ||
        !current.hasNextPage ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await _getWorkerReviewsUseCase(
      GetWorkerReviewsParams(
        workerId: workerId,
        page: nextPage,
        pageSize: _pageSize,
      ),
    );

    result.fold(
      (failure) => emit(WorkerReviewsError(failure.message)),
      (page) => emit(
        current.copyWith(
          reviews: [...current.reviews, ...page.items],
          currentPage: page.page,
          hasNextPage: page.hasNextPage,
          isLoadingMore: false,
        ),
      ),
    );
  }
}

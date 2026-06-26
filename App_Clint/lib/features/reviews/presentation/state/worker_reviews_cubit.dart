import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/review.dart';
import '../../domain/usecases/review_usecases.dart';

sealed class WorkerReviewsState extends Equatable {
  const WorkerReviewsState();

  @override
  List<Object?> get props => [];
}

class WorkerReviewsInitial extends WorkerReviewsState {}

class WorkerReviewsLoading extends WorkerReviewsState {}

class WorkerReviewsLoaded extends WorkerReviewsState {
  const WorkerReviewsLoaded({
    required this.reviews,
    required this.averageRating,
    required this.hasNextPage,
    required this.page,
  });

  final List<Review> reviews;
  final double averageRating;
  final bool hasNextPage;
  final int page;

  @override
  List<Object?> get props =>
      [reviews, averageRating, hasNextPage, page];
}

class WorkerReviewsError extends WorkerReviewsState {
  const WorkerReviewsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class WorkerReviewsCubit extends Cubit<WorkerReviewsState> {
  WorkerReviewsCubit(this._getReviewsByWorkerUseCase)
      : super(WorkerReviewsInitial());

  final GetReviewsByWorkerUseCase _getReviewsByWorkerUseCase;

  Future<void> load(int workerId, {bool loadMore = false}) async {
    if (loadMore) {
      final current = state;
      if (current is! WorkerReviewsLoaded || !current.hasNextPage) return;
      final nextPage = current.page + 1;
      final result = await _getReviewsByWorkerUseCase(
        workerId,
        page: nextPage,
      );
      result.fold(
        (f) => emit(WorkerReviewsError(f.message)),
        (paged) {
          final merged = [...current.reviews, ...paged.items];
          emit(
            WorkerReviewsLoaded(
              reviews: merged,
              averageRating: averageReviewRating(merged),
              hasNextPage: paged.hasNextPage,
              page: paged.page,
            ),
          );
        },
      );
      return;
    }

    emit(WorkerReviewsLoading());
    final result = await _getReviewsByWorkerUseCase(workerId);
    result.fold(
      (f) => emit(WorkerReviewsError(f.message)),
      (paged) => emit(
        WorkerReviewsLoaded(
          reviews: paged.items,
          averageRating: averageReviewRating(paged.items),
          hasNextPage: paged.hasNextPage,
          page: paged.page,
        ),
      ),
    );
  }
}

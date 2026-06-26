import 'package:equatable/equatable.dart';

import '../../domain/entities/review.dart';
import '../../domain/entities/worker_rating_summary.dart';

sealed class WorkerReviewsState extends Equatable {
  const WorkerReviewsState();

  @override
  List<Object?> get props => [];
}

class WorkerReviewsInitial extends WorkerReviewsState {
  const WorkerReviewsInitial();
}

class WorkerReviewsLoading extends WorkerReviewsState {
  const WorkerReviewsLoading();
}

class WorkerReviewsLoaded extends WorkerReviewsState {
  const WorkerReviewsLoaded({
    required this.summary,
    required this.reviews,
    required this.currentPage,
    required this.hasNextPage,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  final WorkerRatingSummary summary;
  final List<Review> reviews;
  final int currentPage;
  final bool hasNextPage;
  final bool isRefreshing;
  final bool isLoadingMore;

  WorkerReviewsLoaded copyWith({
    WorkerRatingSummary? summary,
    List<Review>? reviews,
    int? currentPage,
    bool? hasNextPage,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return WorkerReviewsLoaded(
      summary: summary ?? this.summary,
      reviews: reviews ?? this.reviews,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        reviews,
        currentPage,
        hasNextPage,
        isRefreshing,
        isLoadingMore,
      ];
}

class WorkerReviewsError extends WorkerReviewsState {
  const WorkerReviewsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

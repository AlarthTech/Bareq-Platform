import 'package:equatable/equatable.dart';

class WorkerRatingSummary extends Equatable {
  const WorkerRatingSummary({
    required this.workerId,
    required this.averageRating,
    required this.totalReviews,
  });

  final int workerId;
  final double averageRating;
  final int totalReviews;

  bool get hasReviews => totalReviews > 0;

  @override
  List<Object?> get props => [workerId, averageRating, totalReviews];
}

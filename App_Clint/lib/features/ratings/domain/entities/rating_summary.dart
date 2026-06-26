import 'package:equatable/equatable.dart';

class RatingSummary extends Equatable {
  const RatingSummary({
    required this.averageRating,
    required this.totalReviews,
  });

  final double averageRating;
  final int totalReviews;

  bool get hasReviews => totalReviews > 0;

  @override
  List<Object?> get props => [averageRating, totalReviews];
}

class CompanyRatingSummary extends RatingSummary {
  const CompanyRatingSummary({
    required this.companyId,
    required super.averageRating,
    required super.totalReviews,
    required this.ratedWorkersCount,
    required this.totalActiveWorkers,
  });

  final int companyId;
  final int ratedWorkersCount;
  final int totalActiveWorkers;

  @override
  List<Object?> get props => [
        companyId,
        averageRating,
        totalReviews,
        ratedWorkersCount,
        totalActiveWorkers,
      ];
}

class WorkerRatingSummary extends RatingSummary {
  const WorkerRatingSummary({
    required this.workerId,
    required super.averageRating,
    required super.totalReviews,
  });

  final int workerId;

  @override
  List<Object?> get props => [workerId, averageRating, totalReviews];
}

import 'package:equatable/equatable.dart';

class CompanyRatingSummary extends Equatable {
  const CompanyRatingSummary({
    required this.companyId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratedWorkersCount,
    required this.totalActiveWorkers,
  });

  final int companyId;
  final double averageRating;
  final int totalReviews;
  final int ratedWorkersCount;
  final int totalActiveWorkers;

  bool get hasReviews => totalReviews > 0;

  @override
  List<Object?> get props => [
        companyId,
        averageRating,
        totalReviews,
        ratedWorkersCount,
        totalActiveWorkers,
      ];
}

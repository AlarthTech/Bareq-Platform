import '../../domain/entities/rating_summary.dart';

class RatingSummaryModel {
  RatingSummaryModel({
    required this.averageRating,
    required this.totalReviews,
  });

  final double averageRating;
  final int totalReviews;

  factory RatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return RatingSummaryModel(
      averageRating: _double(json['averageRating']),
      totalReviews: _int(json['totalReviews']) ?? 0,
    );
  }

  RatingSummary toEntity() => RatingSummary(
        averageRating: averageRating,
        totalReviews: totalReviews,
      );

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double _double(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class CompanyRatingSummaryModel extends RatingSummaryModel {
  CompanyRatingSummaryModel({
    required this.companyId,
    required super.averageRating,
    required super.totalReviews,
    required this.ratedWorkersCount,
    required this.totalActiveWorkers,
  });

  final int companyId;
  final int ratedWorkersCount;
  final int totalActiveWorkers;

  factory CompanyRatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return CompanyRatingSummaryModel(
      companyId: RatingSummaryModel._int(json['companyId']) ?? 0,
      averageRating: RatingSummaryModel._double(json['averageRating']),
      totalReviews: RatingSummaryModel._int(json['totalReviews']) ?? 0,
      ratedWorkersCount: RatingSummaryModel._int(json['ratedWorkersCount']) ?? 0,
      totalActiveWorkers:
          RatingSummaryModel._int(json['totalActiveWorkers']) ?? 0,
    );
  }

  CompanyRatingSummary toEntity() => CompanyRatingSummary(
        companyId: companyId,
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratedWorkersCount: ratedWorkersCount,
        totalActiveWorkers: totalActiveWorkers,
      );
}

class WorkerRatingSummaryModel extends RatingSummaryModel {
  WorkerRatingSummaryModel({
    required this.workerId,
    required super.averageRating,
    required super.totalReviews,
  });

  final int workerId;

  factory WorkerRatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return WorkerRatingSummaryModel(
      workerId: RatingSummaryModel._int(json['workerId']) ?? 0,
      averageRating: RatingSummaryModel._double(json['averageRating']),
      totalReviews: RatingSummaryModel._int(json['totalReviews']) ?? 0,
    );
  }

  WorkerRatingSummary toEntity() => WorkerRatingSummary(
        workerId: workerId,
        averageRating: averageRating,
        totalReviews: totalReviews,
      );
}

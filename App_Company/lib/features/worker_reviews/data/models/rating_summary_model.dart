import '../../domain/entities/company_rating_summary.dart';
import '../../domain/entities/worker_rating_summary.dart';

class CompanyRatingSummaryModel extends CompanyRatingSummary {
  const CompanyRatingSummaryModel({
    required super.companyId,
    required super.averageRating,
    required super.totalReviews,
    required super.ratedWorkersCount,
    required super.totalActiveWorkers,
  });

  factory CompanyRatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return CompanyRatingSummaryModel(
      companyId: _asInt(json['companyId']),
      averageRating: _asDouble(json['averageRating']),
      totalReviews: _asInt(json['totalReviews']),
      ratedWorkersCount: _asInt(json['ratedWorkersCount']),
      totalActiveWorkers: _asInt(json['totalActiveWorkers']),
    );
  }

  CompanyRatingSummary toEntity() => CompanyRatingSummary(
        companyId: companyId,
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratedWorkersCount: ratedWorkersCount,
        totalActiveWorkers: totalActiveWorkers,
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class WorkerRatingSummaryModel extends WorkerRatingSummary {
  const WorkerRatingSummaryModel({
    required super.workerId,
    required super.averageRating,
    required super.totalReviews,
  });

  factory WorkerRatingSummaryModel.fromJson(Map<String, dynamic> json) {
    return WorkerRatingSummaryModel(
      workerId: _asInt(json['workerId']),
      averageRating: _asDouble(json['averageRating']),
      totalReviews: _asInt(json['totalReviews']),
    );
  }

  WorkerRatingSummary toEntity() => WorkerRatingSummary(
        workerId: workerId,
        averageRating: averageRating,
        totalReviews: totalReviews,
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

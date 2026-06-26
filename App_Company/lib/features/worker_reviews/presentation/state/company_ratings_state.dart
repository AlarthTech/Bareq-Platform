import 'package:equatable/equatable.dart';

import '../../domain/entities/company_rating_summary.dart';
import '../../domain/entities/worker_rating_row.dart';
import '../../domain/usecases/get_company_workers_with_ratings.dart';

sealed class CompanyRatingsState extends Equatable {
  const CompanyRatingsState();

  @override
  List<Object?> get props => [];
}

class CompanyRatingsInitial extends CompanyRatingsState {
  const CompanyRatingsInitial();
}

class CompanyRatingsLoading extends CompanyRatingsState {
  const CompanyRatingsLoading();
}

class CompanyRatingsLoaded extends CompanyRatingsState {
  const CompanyRatingsLoaded({
    required this.data,
    this.isRefreshing = false,
  });

  final CompanyWorkersWithRatings data;
  final bool isRefreshing;

  CompanyRatingSummary get companySummary => data.companySummary;
  List<WorkerRatingRow> get rows => data.rows;

  CompanyRatingsLoaded copyWith({
    CompanyWorkersWithRatings? data,
    bool? isRefreshing,
  }) {
    return CompanyRatingsLoaded(
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [data, isRefreshing];
}

class CompanyRatingsError extends CompanyRatingsState {
  const CompanyRatingsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

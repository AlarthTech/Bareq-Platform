import 'package:equatable/equatable.dart';

import '../../../workers/domain/entities/worker_entity.dart';
import 'worker_rating_summary.dart';

class WorkerRatingRow extends Equatable {
  const WorkerRatingRow({
    required this.worker,
    this.summary,
  });

  final WorkerEntity worker;
  final WorkerRatingSummary? summary;

  bool get hasReviews => summary != null && summary!.hasReviews;

  @override
  List<Object?> get props => [worker, summary];
}

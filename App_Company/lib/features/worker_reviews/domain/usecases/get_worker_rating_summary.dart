import '../../../../core/error/failures.dart';
import '../entities/worker_rating_summary.dart';
import '../repositories/worker_reviews_repository.dart';
import 'package:dartz/dartz.dart';

class GetWorkerRatingSummaryUseCase {
  GetWorkerRatingSummaryUseCase(this.repository);

  final WorkerReviewsRepository repository;

  Future<Either<Failure, WorkerRatingSummary>> call(int workerId) {
    return repository.getWorkerRatingSummary(workerId);
  }
}

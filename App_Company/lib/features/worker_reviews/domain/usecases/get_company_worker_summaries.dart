import '../../../../core/error/failures.dart';
import '../entities/worker_rating_summary.dart';
import '../repositories/worker_reviews_repository.dart';
import 'package:dartz/dartz.dart';

class GetCompanyWorkerSummariesUseCase {
  GetCompanyWorkerSummariesUseCase(this.repository);

  final WorkerReviewsRepository repository;

  Future<Either<Failure, List<WorkerRatingSummary>>> call(int companyId) {
    return repository.getCompanyWorkerSummaries(companyId);
  }
}

import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/rating_summary.dart';

abstract class RatingRepository {
  Future<Either<Failure, WorkerRatingSummary>> getWorkerSummary(int workerId);

  Future<Either<Failure, CompanyRatingSummary>> getCompanySummary(int companyId);

  Future<Either<Failure, List<WorkerRatingSummary>>> getCompanyWorkerSummaries(
    int companyId,
  );

  void invalidateWorker(int workerId);

  void invalidateCompany(int companyId);
}

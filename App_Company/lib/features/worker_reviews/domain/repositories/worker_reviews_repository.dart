import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/company_rating_summary.dart';
import '../entities/review.dart';
import '../entities/worker_rating_summary.dart';
import 'package:dartz/dartz.dart';

abstract class WorkerReviewsRepository {
  Future<Either<Failure, CompanyRatingSummary>> getCompanyRatingSummary(
    int companyId,
  );

  Future<Either<Failure, List<WorkerRatingSummary>>> getCompanyWorkerSummaries(
    int companyId,
  );

  Future<Either<Failure, WorkerRatingSummary>> getWorkerRatingSummary(
    int workerId,
  );

  Future<Either<Failure, PagedResult<Review>>> getWorkerReviews(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Review>> getReviewById(int reviewId);
}

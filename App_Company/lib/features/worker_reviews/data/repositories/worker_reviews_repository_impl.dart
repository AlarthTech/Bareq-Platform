import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/company_rating_summary.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/worker_rating_summary.dart';
import '../../domain/repositories/worker_reviews_repository.dart';
import '../datasources/worker_reviews_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class WorkerReviewsRepositoryImpl implements WorkerReviewsRepository {
  WorkerReviewsRepositoryImpl(this.remoteDataSource);

  final WorkerReviewsRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, CompanyRatingSummary>> getCompanyRatingSummary(
    int companyId,
  ) async {
    try {
      final model = await remoteDataSource.getCompanyRatingSummary(companyId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<WorkerRatingSummary>>> getCompanyWorkerSummaries(
    int companyId,
  ) async {
    try {
      final models = await remoteDataSource.getCompanyWorkerSummaries(companyId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, WorkerRatingSummary>> getWorkerRatingSummary(
    int workerId,
  ) async {
    try {
      final model = await remoteDataSource.getWorkerRatingSummary(workerId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, PagedResult<Review>>> getWorkerReviews(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageResult = await remoteDataSource.getWorkerReviews(
        workerId,
        page: page,
        pageSize: pageSize,
      );
      return Right(
        PagedResult<Review>(
          items: pageResult.items.map((m) => m.toEntity()).toList(),
          page: pageResult.page,
          pageSize: pageResult.pageSize,
          totalCount: pageResult.totalCount,
          totalPages: pageResult.totalPages,
          hasNextPage: pageResult.hasNextPage,
          hasPreviousPage: pageResult.hasPreviousPage,
        ),
      );
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, Review>> getReviewById(int reviewId) async {
    try {
      final model = await remoteDataSource.getReviewById(reviewId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}

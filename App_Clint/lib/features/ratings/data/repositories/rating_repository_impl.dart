import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/rating_summary.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_cache.dart';
import '../datasources/rating_remote_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl({
    required RatingRemoteDataSource remoteDataSource,
    required RatingCache cache,
  })  : _remoteDataSource = remoteDataSource,
        _cache = cache;

  final RatingRemoteDataSource _remoteDataSource;
  final RatingCache _cache;

  @override
  Future<Either<Failure, WorkerRatingSummary>> getWorkerSummary(
    int workerId,
  ) async {
    final cached = _cache.getWorker(workerId);
    if (cached != null) return Right(cached);

    try {
      final model = await _remoteDataSource.getWorkerSummary(workerId);
      final summary = WorkerRatingSummary(
        workerId: workerId,
        averageRating: model.averageRating,
        totalReviews: model.totalReviews,
      );
      _cache.putWorker(summary);
      return Right(summary);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CompanyRatingSummary>> getCompanySummary(
    int companyId,
  ) async {
    final cached = _cache.getCompany(companyId);
    if (cached != null) return Right(cached);

    try {
      final model = await _remoteDataSource.getCompanySummary(companyId);
      final summary = model.toEntity();
      _cache.putCompany(summary);
      return Right(summary);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkerRatingSummary>>> getCompanyWorkerSummaries(
    int companyId,
  ) async {
    final cached = _cache.getCompanyWorkers(companyId);
    if (cached != null) return Right(cached);

    try {
      final models =
          await _remoteDataSource.getCompanyWorkerSummaries(companyId);
      final summaries = models.map((m) => m.toEntity()).toList();
      _cache.putCompanyWorkers(companyId, summaries);
      return Right(summaries);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  void invalidateWorker(int workerId) => _cache.invalidateWorker(workerId);

  @override
  void invalidateCompany(int companyId) => _cache.invalidateCompany(companyId);
}

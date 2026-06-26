import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/rating_summary.dart';
import '../repositories/rating_repository.dart';

class GetWorkerRatingSummaryUseCase {
  GetWorkerRatingSummaryUseCase(this._repository);

  final RatingRepository _repository;

  Future<Either<Failure, WorkerRatingSummary>> call(int workerId) {
    return _repository.getWorkerSummary(workerId);
  }
}

class GetCompanyRatingSummaryUseCase {
  GetCompanyRatingSummaryUseCase(this._repository);

  final RatingRepository _repository;

  Future<Either<Failure, CompanyRatingSummary>> call(int companyId) {
    return _repository.getCompanySummary(companyId);
  }
}

class GetCompanyWorkerSummariesUseCase {
  GetCompanyWorkerSummariesUseCase(this._repository);

  final RatingRepository _repository;

  Future<Either<Failure, List<WorkerRatingSummary>>> call(int companyId) {
    return _repository.getCompanyWorkerSummaries(companyId);
  }
}

class InvalidateRatingCacheUseCase {
  InvalidateRatingCacheUseCase(this._repository);

  final RatingRepository _repository;

  void forWorker(int workerId, {int? companyId}) {
    _repository.invalidateWorker(workerId);
    if (companyId != null) {
      _repository.invalidateCompany(companyId);
    }
  }

  void forCompany(int companyId) {
    _repository.invalidateCompany(companyId);
  }
}

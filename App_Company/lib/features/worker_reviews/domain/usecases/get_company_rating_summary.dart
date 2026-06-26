import '../../../../core/error/failures.dart';
import '../entities/company_rating_summary.dart';
import '../repositories/worker_reviews_repository.dart';
import 'package:dartz/dartz.dart';

class GetCompanyRatingSummaryUseCase {
  GetCompanyRatingSummaryUseCase(this.repository);

  final WorkerReviewsRepository repository;

  Future<Either<Failure, CompanyRatingSummary>> call(int companyId) {
    return repository.getCompanyRatingSummary(companyId);
  }
}

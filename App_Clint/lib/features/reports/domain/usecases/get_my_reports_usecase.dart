import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';

class GetMyReportsUseCase {
  GetMyReportsUseCase(this._repository);

  final ReportRepository _repository;

  Future<Either<Failure, PagedResult<Report>>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getMyReports(page: page, pageSize: pageSize);
  }
}

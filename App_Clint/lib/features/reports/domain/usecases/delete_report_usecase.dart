import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/report_repository.dart';

class DeleteReportUseCase {
  DeleteReportUseCase(this._repository);

  final ReportRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.deleteReport(id);
  }
}

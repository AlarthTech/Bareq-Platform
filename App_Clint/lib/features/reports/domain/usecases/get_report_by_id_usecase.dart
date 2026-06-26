import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';

class GetReportByIdUseCase {
  GetReportByIdUseCase(this._repository);

  final ReportRepository _repository;

  Future<Either<Failure, Report>> call(int id) {
    return _repository.getReportById(id);
  }
}

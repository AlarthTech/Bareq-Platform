import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';

class CreateReportUseCase {
  CreateReportUseCase(this._repository);

  final ReportRepository _repository;

  Future<Either<Failure, Report>> createWorkerReport({
    required int workerId,
    required String description,
  }) {
    return _repository.createWorkerReport(
      workerId: workerId,
      description: description,
    );
  }

  Future<Either<Failure, Report>> createCompanyReport({
    required int companyId,
    required String description,
  }) {
    return _repository.createCompanyReport(
      companyId: companyId,
      description: description,
    );
  }
}

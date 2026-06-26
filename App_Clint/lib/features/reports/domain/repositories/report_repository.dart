import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/report.dart';

abstract class ReportRepository {
  Future<Either<Failure, Report>> createWorkerReport({
    required int workerId,
    required String description,
  });

  Future<Either<Failure, Report>> createCompanyReport({
    required int companyId,
    required String description,
  });

  Future<Either<Failure, PagedResult<Report>>> getMyReports({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Report>> getReportById(int id);

  Future<Either<Failure, void>> deleteReport(int id);
}

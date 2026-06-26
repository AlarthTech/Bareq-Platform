import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._remote);

  final ReportRemoteDataSource _remote;

  @override
  Future<Either<Failure, Report>> createWorkerReport({
    required int workerId,
    required String description,
  }) async {
    try {
      final model = await _remote.createWorkerReport(workerId, description);
      return Right(model.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Report>> createCompanyReport({
    required int companyId,
    required String description,
  }) async {
    try {
      final model = await _remote.createCompanyReport(companyId, description);
      return Right(model.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<Report>>> getMyReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageResult = await _remote.getMyReports(
        page: page,
        pageSize: pageSize,
      );
      return Right(
        PagedResult<Report>(
          items: pageResult.items.map((m) => m.toEntity()).toList(),
          page: pageResult.page,
          pageSize: pageResult.pageSize,
          totalCount: pageResult.totalCount,
          totalPages: pageResult.totalPages,
          hasNextPage: pageResult.hasNextPage,
          hasPreviousPage: pageResult.hasPreviousPage,
        ),
      );
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Report>> getReportById(int id) async {
    try {
      final model = await _remote.getReportById(id);
      return Right(model.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport(int id) async {
    try {
      await _remote.deleteReport(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}

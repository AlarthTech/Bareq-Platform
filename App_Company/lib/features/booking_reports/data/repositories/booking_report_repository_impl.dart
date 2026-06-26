import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/repositories/booking_report_repository.dart';
import '../datasources/booking_report_remote_datasource.dart';

class BookingReportRepositoryImpl implements BookingReportRepository {
  BookingReportRepositoryImpl(this._remoteDataSource);

  final BookingReportRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, PagedResult<BookingReport>>> getCompanyBookingReports({
    BookingReportFilters? filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageResult = await _remoteDataSource.getCompanyBookingReports(
        filters: filters,
        page: page,
        pageSize: pageSize,
      );
      return Right(
        PagedResult<BookingReport>(
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
  Future<Either<Failure, BookingReport>> getBookingReportById(int id) async {
    try {
      final model = await _remoteDataSource.getBookingReportById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, BookingReport>> updateBookingReportStatus({
    required int id,
    required int status,
    String? adminResolutionNotes,
  }) async {
    try {
      final model = await _remoteDataSource.updateBookingReportStatus(
        id: id,
        status: status,
        adminResolutionNotes: adminResolutionNotes,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}

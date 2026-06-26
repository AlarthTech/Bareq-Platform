import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/repositories/booking_report_repository.dart';
import '../datasources/booking_report_remote_datasource.dart';
import '../models/booking_report_model.dart';

class BookingReportRepositoryImpl implements BookingReportRepository {
  BookingReportRepositoryImpl(this._remote);

  final BookingReportRemoteDataSource _remote;

  @override
  Future<Either<Failure, BookingReport>> createBookingReport({
    required int bookingId,
    required String reason,
    String? description,
  }) async {
    try {
      final model = await _remote.createBookingReport(
        bookingId: bookingId,
        reason: reason,
        description: description,
      );
      return Right(model.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<BookingReport>>> getMyBookingReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageResult = await _remote.getMyBookingReports(
        page: page,
        pageSize: pageSize,
      );
      return Right(_mapPage(pageResult));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<BookingReport>>> getReportsByBookingId({
    required int bookingId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageResult = await _remote.getReportsByBookingId(
        bookingId: bookingId,
        page: page,
        pageSize: pageSize,
      );
      return Right(_mapPage(pageResult));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  PagedResult<BookingReport> _mapPage(
    PagedResult<BookingReportModel> pageResult,
  ) {
    return PagedResult<BookingReport>(
      items: pageResult.items.map((m) => m.toEntity()).toList(),
      page: pageResult.page,
      pageSize: pageResult.pageSize,
      totalCount: pageResult.totalCount,
      totalPages: pageResult.totalPages,
      hasNextPage: pageResult.hasNextPage,
      hasPreviousPage: pageResult.hasPreviousPage,
    );
  }
}

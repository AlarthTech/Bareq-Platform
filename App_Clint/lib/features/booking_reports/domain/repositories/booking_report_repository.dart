import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking_report.dart';

abstract class BookingReportRepository {
  Future<Either<Failure, BookingReport>> createBookingReport({
    required int bookingId,
    required String reason,
    String? description,
  });

  Future<Either<Failure, PagedResult<BookingReport>>> getMyBookingReports({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PagedResult<BookingReport>>> getReportsByBookingId({
    required int bookingId,
    int page = 1,
    int pageSize = 20,
  });
}

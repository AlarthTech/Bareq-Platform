import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_report.dart';

abstract class BookingReportRepository {
  Future<Either<Failure, PagedResult<BookingReport>>> getCompanyBookingReports({
    BookingReportFilters? filters,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, BookingReport>> getBookingReportById(int id);

  Future<Either<Failure, BookingReport>> updateBookingReportStatus({
    required int id,
    required int status,
    String? adminResolutionNotes,
  });
}

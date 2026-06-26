import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking_report.dart';
import '../repositories/booking_report_repository.dart';

class GetBookingReportsByBookingUseCase {
  GetBookingReportsByBookingUseCase(this._repository);

  final BookingReportRepository _repository;

  Future<Either<Failure, PagedResult<BookingReport>>> call({
    required int bookingId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getReportsByBookingId(
      bookingId: bookingId,
      page: page,
      pageSize: pageSize,
    );
  }
}

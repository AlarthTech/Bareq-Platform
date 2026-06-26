import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking_report.dart';
import '../repositories/booking_report_repository.dart';

class CreateBookingReportUseCase {
  CreateBookingReportUseCase(this._repository);

  final BookingReportRepository _repository;

  Future<Either<Failure, BookingReport>> call({
    required int bookingId,
    required String reason,
    String? description,
  }) {
    return _repository.createBookingReport(
      bookingId: bookingId,
      reason: reason,
      description: description,
    );
  }
}

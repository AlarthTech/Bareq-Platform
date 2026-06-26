import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../repositories/booking_repository.dart';

/// Use case for updating booking status
class UpdateBookingStatusUseCase {
  final BookingRepository repository;

  UpdateBookingStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(
    int bookingId,
    int status, {
    String? rejectionReason,
  }) async {
    return await repository.updateBookingStatus(
      bookingId,
      status,
      rejectionReason: rejectionReason,
    );
  }
}

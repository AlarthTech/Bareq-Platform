import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

/// Fetch bookings by user id route used by backend.
class GetMyBookingsUseCase {
  final BookingRepository repository;

  GetMyBookingsUseCase(this.repository);

  Future<Either<Failure, List<Booking>>> call(int userId) async {
    return repository.getUserBookings(userId);
  }
}

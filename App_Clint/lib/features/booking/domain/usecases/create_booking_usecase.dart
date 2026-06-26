import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../entities/booking_request.dart';
import '../repositories/booking_repository.dart';

/// Creates a booking (POST /api/Bookings/CreateBooking).
/// Returns [Booking] on 201; [BookingConflictFailure] on 409 with API `detail`.
class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  Future<Either<Failure, Booking>> call(BookingRequest bookingRequest) async {
    if (!bookingRequest.acceptedResponsibilityNotice) {
      return const Left<Failure, Booking>(
        ValidationFailure(
          'Please accept the service responsibility notice to continue.',
        ),
      );
    }
    return repository.createBooking(bookingRequest);
  }
}

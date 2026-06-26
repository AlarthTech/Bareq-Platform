import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking.dart';
import '../entities/booking_status_codes.dart';
import '../repositories/booking_repository.dart';

/// Returns the user's ongoing bookings (pending, approved, on the way), prioritized.
class GetOngoingBookingsUseCase {
  GetOngoingBookingsUseCase(this._repository);

  final BookingRepository _repository;

  Future<Either<Failure, List<Booking>>> call(int userId) async {
    final result = await _repository.getUserBookings(userId);
    return result.fold(
      Left.new,
      (bookings) => Right(_filterAndSort(bookings)),
    );
  }

  List<Booking> _filterAndSort(List<Booking> bookings) {
    final ongoing =
        bookings
            .where((b) => BookingStatusCodes.isOngoing(b.status))
            .toList();
    ongoing.sort(_compareOngoing);
    return ongoing;
  }

  int _compareOngoing(Booking a, Booking b) {
    final statusOrder = BookingStatusCodes.onTheWay == a.status
        ? 0
        : BookingStatusCodes.approved == a.status
        ? 1
        : 2;
    final statusOrderB = BookingStatusCodes.onTheWay == b.status
        ? 0
        : BookingStatusCodes.approved == b.status
        ? 1
        : 2;
    final byStatus = statusOrder.compareTo(statusOrderB);
    if (byStatus != 0) return byStatus;
    return a.bookingDate.compareTo(b.bookingDate);
  }
}

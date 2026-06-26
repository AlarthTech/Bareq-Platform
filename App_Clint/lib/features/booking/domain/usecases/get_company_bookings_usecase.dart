import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

/// Bookings for one company (CleaningHouse: GET /api/Bookings/Company/{companyId}).
class GetCompanyBookingsUseCase {
  final BookingRepository repository;

  GetCompanyBookingsUseCase(this.repository);

  Future<Either<Failure, List<Booking>>> call(int companyId) {
    return repository.getCompanyBookings(companyId);
  }
}

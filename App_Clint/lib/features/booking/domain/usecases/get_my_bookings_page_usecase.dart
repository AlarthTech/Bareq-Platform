import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paged_result.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class GetMyBookingsPageUseCase {
  final BookingRepository repository;

  GetMyBookingsPageUseCase(this.repository);

  Future<Either<Failure, PagedResult<Booking>>> call(
    int userId, {
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getUserBookingsPage(
      userId,
      page: page,
      pageSize: pageSize,
    );
  }
}

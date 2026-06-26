import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paged_result.dart';
import '../entities/work_type.dart';
import '../entities/work_type_detail.dart';
import '../entities/booking_request.dart';
import '../entities/booking.dart';
import '../entities/review_request.dart';

abstract class BookingRepository {
  Future<List<WorkType>> getWorkerWorkTypes(int workerId);

  Future<List<WorkType>> getWorkTypesByCompany(int companyId);

  Future<Either<Failure, List<WorkTypeDetail>>> getAllWorkTypes();

  Future<Either<Failure, PagedResult<Booking>>> getUserBookingsPage(
    int userId, {
    int page = 1,
    int pageSize = 20,
  });

  /// Loads all user booking pages (for duplicate checks).
  Future<Either<Failure, List<Booking>>> getUserBookings(int userId);

  Future<Either<Failure, List<Booking>>> getCompanyBookings(int companyId);

  Future<Either<Failure, Booking>> createBooking(BookingRequest bookingRequest);

  Future<Either<Failure, void>> updateBookingStatus(
    int bookingId,
    int status, {
    String? rejectionReason,
  });

  Future<Either<Failure, void>> confirmWorkerArrival(int bookingId);

  Future<Either<Failure, void>> submitReview(ReviewRequest reviewRequest);
}

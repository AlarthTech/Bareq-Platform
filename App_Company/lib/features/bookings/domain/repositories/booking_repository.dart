import '../entities/booking_entity.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class BookingRepository {
  Future<Either<Failure, PagedResult<BookingEntity>>> getBookingsByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  });
  Future<Either<Failure, BookingEntity>> getBookingById(int bookingId);
  Future<Either<Failure, void>> updateBookingStatus(
    int bookingId,
    int statusValue, {
    String? rejectionReason,
  });
}

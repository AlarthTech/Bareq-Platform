import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class GetBookingByIdUseCase {
  final BookingRepository repository;

  GetBookingByIdUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call(int bookingId) {
    return repository.getBookingById(bookingId);
  }
}

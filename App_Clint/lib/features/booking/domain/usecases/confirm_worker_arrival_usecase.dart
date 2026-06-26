import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/booking_repository.dart';

class ConfirmWorkerArrivalUseCase {
  ConfirmWorkerArrivalUseCase(this._repository);

  final BookingRepository _repository;

  Future<Either<Failure, void>> call(int bookingId) {
    return _repository.confirmWorkerArrival(bookingId);
  }
}

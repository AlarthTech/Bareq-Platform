import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_type_detail.dart';
import '../repositories/booking_repository.dart';

/// Use case for getting all work types
class GetAllWorkTypesUseCase {
  final BookingRepository repository;

  GetAllWorkTypesUseCase(this.repository);

  Future<Either<Failure, List<WorkTypeDetail>>> call() async {
    return await repository.getAllWorkTypes();
  }
}

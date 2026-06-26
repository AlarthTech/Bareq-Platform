import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_location.dart';
import '../repositories/user_locations_repository.dart';

class GetMyLocationsUseCase {
  final UserLocationsRepository repository;

  GetMyLocationsUseCase(this.repository);

  Future<Either<Failure, List<UserLocation>>> call() =>
      repository.getMyLocations();
}

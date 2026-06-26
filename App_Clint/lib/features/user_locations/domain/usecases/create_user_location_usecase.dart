import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_location.dart';
import '../repositories/user_locations_repository.dart';

class CreateUserLocationUseCase {
  final UserLocationsRepository repository;

  CreateUserLocationUseCase(this.repository);

  Future<Either<Failure, UserLocation>> call({
    required String locationName,
    required double lat,
    required double lng,
  }) => repository.create(
    locationName: locationName,
    lat: lat,
    lng: lng,
  );
}

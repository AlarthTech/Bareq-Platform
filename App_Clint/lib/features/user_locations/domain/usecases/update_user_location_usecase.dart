import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_location.dart';
import '../repositories/user_locations_repository.dart';

class UpdateUserLocationUseCase {
  final UserLocationsRepository repository;

  UpdateUserLocationUseCase(this.repository);

  Future<Either<Failure, UserLocation>> call({
    required int id,
    String? locationName,
    double? lat,
    double? lng,
  }) => repository.update(
    id: id,
    locationName: locationName,
    lat: lat,
    lng: lng,
  );
}

import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/user_locations_repository.dart';

class DeleteUserLocationUseCase {
  final UserLocationsRepository repository;

  DeleteUserLocationUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.delete(id);
}

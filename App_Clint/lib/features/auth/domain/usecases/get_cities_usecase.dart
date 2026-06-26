import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/city.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting all cities
/// Encapsulates business logic for fetching cities
class GetCitiesUseCase {
  final AuthRepository repository;

  GetCitiesUseCase(this.repository);

  Future<Either<Failure, List<City>>> call() async {
    return await repository.getAllCities();
  }
}


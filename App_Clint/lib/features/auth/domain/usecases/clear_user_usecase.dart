import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

/// Use case for clearing user data (logout)
/// Encapsulates business logic for user logout
class ClearUserUseCase {
  final AuthRepository repository;

  ClearUserUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearUser();
  }
}


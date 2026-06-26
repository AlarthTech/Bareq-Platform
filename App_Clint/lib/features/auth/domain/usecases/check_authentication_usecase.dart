import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking if user is authenticated
/// Encapsulates business logic for authentication state checking
class CheckAuthenticationUseCase {
  final AuthRepository repository;

  CheckAuthenticationUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.isAuthenticated();
  }
}


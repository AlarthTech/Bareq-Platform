import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
/// Encapsulates business logic for user authentication
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String username,
    required String password,
  }) async {
    // Business logic validation
    if (username.trim().isEmpty) {
      return const Left(ValidationFailure('Username is required'));
    }

    if (password.isEmpty) {
      return const Left(ValidationFailure('Password is required'));
    }

    // Call repository
    return await repository.login(
      username: username.trim(),
      password: password,
    );
  }
}


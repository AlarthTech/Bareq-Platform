import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for saving user to local storage
/// Encapsulates business logic for persisting user data
class SaveUserUseCase {
  final AuthRepository repository;

  SaveUserUseCase(this.repository);

  Future<Either<Failure, void>> call(User user) async {
    return await repository.saveUser(user);
  }
}


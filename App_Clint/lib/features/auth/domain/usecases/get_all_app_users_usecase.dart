import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting all app users (customers)
class GetAllAppUsersUseCase {
  final AuthRepository repository;

  GetAllAppUsersUseCase(this.repository);

  Future<Either<Failure, List<User>>> call() async {
    return await repository.getAllAppUsers();
  }
}

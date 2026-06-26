import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class ChangePersonalInfoUseCase {
  final AuthRepository repository;

  ChangePersonalInfoUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String fullName,
    required String email,
  }) {
    return repository.changePersonalInfo(fullName: fullName, email: email);
  }
}

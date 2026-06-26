import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class ChangePhoneUseCase {
  final AuthRepository repository;

  ChangePhoneUseCase(this.repository);

  Future<Either<Failure, User>> call(String newPhone) {
    return repository.changePhone(newPhone);
  }
}

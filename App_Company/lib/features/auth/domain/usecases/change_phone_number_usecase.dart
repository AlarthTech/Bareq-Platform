import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class ChangePhoneNumberUseCase {
  final AuthRepository repository;

  ChangePhoneNumberUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String phoneNumber) {
    return repository.changePhoneNumber(phoneNumber);
  }
}

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class ChangePersonalInfoParams {
  final String fullName;
  final String? email;

  const ChangePersonalInfoParams({required this.fullName, this.email});
}

class ChangePersonalInfoUseCase {
  final AuthRepository repository;

  ChangePersonalInfoUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(ChangePersonalInfoParams params) {
    return repository.changePersonalInfo(
      fullName: params.fullName,
      email: params.email,
    );
  }
}

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class RegisterUseCase {
  final AuthRepository repository;
  
  RegisterUseCase(this.repository);
  
  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    return await repository.register(
      fullName: params.fullName,
      phone: params.phone,
      email: params.email,
      password: params.password,
      cityId: params.cityId,
    );
  }
}

class RegisterParams extends Equatable {
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final int? cityId;

  const RegisterParams({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    this.cityId,
  });

  @override
  List<Object?> get props => [fullName, phone, email, password, cityId];
}

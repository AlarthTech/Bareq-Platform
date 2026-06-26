import '../entities/user_entity.dart';
import '../entities/auth_session.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> login(String username, String password);
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    int? cityId,
  });
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Either<Failure, UserEntity>> changePersonalInfo({
    required String fullName,
    String? email,
  });
  Future<Either<Failure, UserEntity>> changePhoneNumber(String phoneNumber);
  Future<Either<Failure, void>> deleteMyCompanyAccount(String password);
}

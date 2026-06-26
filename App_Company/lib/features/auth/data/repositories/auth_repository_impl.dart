import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_session.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/auth_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ApiClient apiClient;

  AuthRepositoryImpl(this.remoteDataSource, this.apiClient);

  @override
  Future<Either<Failure, AuthSession>> login(
    String username,
    String password,
  ) async {
    try {
      apiClient.clearAuthToken();
      final response = await remoteDataSource.login(username, password);
      final token = response.token?.trim();
      if (response.user != null && token != null && token.isNotEmpty) {
        apiClient.setAuthToken(token);
        return Right(
          AuthSession(user: response.user!.toEntity(), token: token),
        );
      }
      if (response.success && response.user != null) {
        return Left(
          ServerFailure(
            response.message ?? 'لم يُستلم رمز المصادقة من الخادم',
          ),
        );
      }
      return Left(ServerFailure(response.message ?? 'فشل تسجيل الدخول'));
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    int? cityId,
  }) async {
    try {
      final user = await remoteDataSource.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        cityId: cityId,
      );
      return Right(user.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> changePersonalInfo({
    required String fullName,
    String? email,
  }) async {
    try {
      final user = await remoteDataSource.changePersonalInfo(
        fullName: fullName,
        email: email,
      );
      return Right(user.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> changePhoneNumber(String phoneNumber) async {
    try {
      final user = await remoteDataSource.changePhoneNumber(phoneNumber);
      return Right(user.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMyCompanyAccount(String password) async {
    try {
      await remoteDataSource.deleteMyCompanyAccount(password);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}

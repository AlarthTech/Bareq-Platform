import '../../domain/repositories/forgot_password_repository.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../datasources/forgot_password_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  ForgotPasswordRepositoryImpl(this.remoteDataSource);

  final ForgotPasswordRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, String>> requestOtp(String email) async {
    try {
      final message = await remoteDataSource.requestOtp(email);
      return Right(message);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, String>> verifyCode(String email, String code) async {
    try {
      final token = await remoteDataSource.verifyCode(email, code);
      return Right(token);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final message = await remoteDataSource.resetPassword(
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
      );
      return Right(message);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}

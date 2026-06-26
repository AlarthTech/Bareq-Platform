import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/forgot_password_repository.dart';
import '../datasources/forgot_password_remote_datasource.dart';

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  ForgotPasswordRepositoryImpl(this._remote);

  final ForgotPasswordRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> requestOtp(String identifier) async {
    try {
      final message = await _remote.requestOtp(identifier);
      return Right(message);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> verifyCode(
    String identifier,
    String code,
  ) async {
    try {
      final token = await _remote.verifyResetCode(
        identifier: identifier,
        code: code,
      );
      return Right(token);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final message = await _remote.resetPassword(
        identifier: identifier,
        resetToken: resetToken,
        newPassword: newPassword,
      );
      return Right(message);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

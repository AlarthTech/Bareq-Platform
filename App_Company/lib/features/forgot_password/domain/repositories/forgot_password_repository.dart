import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class ForgotPasswordRepository {
  Future<Either<Failure, String>> requestOtp(String email);
  Future<Either<Failure, String>> verifyCode(String email, String code);
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  });
}

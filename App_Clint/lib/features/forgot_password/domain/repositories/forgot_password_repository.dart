import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';

abstract class ForgotPasswordRepository {
  /// [identifier] is sent as API `email` (email or phone). Always generic 200 on success.
  Future<Either<Failure, String>> requestOtp(String identifier);

  Future<Either<Failure, String>> verifyCode(
    String identifier,
    String code,
  );

  Future<Either<Failure, String>> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
  });
}

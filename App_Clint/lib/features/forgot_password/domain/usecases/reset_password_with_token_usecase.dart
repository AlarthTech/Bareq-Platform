import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/forgot_password_repository.dart';

class ResetPasswordWithTokenUseCase {
  ResetPasswordWithTokenUseCase(this._repository);

  final ForgotPasswordRepository _repository;

  Future<Either<Failure, String>> call({
    required String identifier,
    required String resetToken,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      identifier: identifier.trim(),
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}

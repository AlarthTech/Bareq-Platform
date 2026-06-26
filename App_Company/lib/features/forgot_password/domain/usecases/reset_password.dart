import '../repositories/forgot_password_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class ResetPasswordUseCase {
  final ForgotPasswordRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String email,
    required String resetToken,
    required String newPassword,
  }) {
    return repository.resetPassword(
      email: email,
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}

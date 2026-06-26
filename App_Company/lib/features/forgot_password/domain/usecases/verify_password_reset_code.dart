import '../repositories/forgot_password_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class VerifyPasswordResetCodeUseCase {
  final ForgotPasswordRepository repository;

  VerifyPasswordResetCodeUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String email,
    required String code,
  }) {
    return repository.verifyCode(email, code);
  }
}

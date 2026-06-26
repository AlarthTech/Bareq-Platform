import '../repositories/forgot_password_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class RequestPasswordResetOtpUseCase {
  final ForgotPasswordRepository repository;

  RequestPasswordResetOtpUseCase(this.repository);

  Future<Either<Failure, String>> call(String email) {
    return repository.requestOtp(email);
  }
}

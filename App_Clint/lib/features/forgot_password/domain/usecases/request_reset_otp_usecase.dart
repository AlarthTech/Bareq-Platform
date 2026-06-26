import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/forgot_password_repository.dart';

class RequestResetOtpUseCase {
  RequestResetOtpUseCase(this._repository);

  final ForgotPasswordRepository _repository;

  Future<Either<Failure, String>> call(String identifier) {
    return _repository.requestOtp(identifier.trim());
  }
}

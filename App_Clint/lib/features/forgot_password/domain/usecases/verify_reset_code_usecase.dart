import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/forgot_password_repository.dart';

class VerifyResetCodeUseCase {
  VerifyResetCodeUseCase(this._repository);

  final ForgotPasswordRepository _repository;

  Future<Either<Failure, String>> call({
    required String identifier,
    required String code,
  }) {
    return _repository.verifyCode(identifier.trim(), code.trim());
  }
}

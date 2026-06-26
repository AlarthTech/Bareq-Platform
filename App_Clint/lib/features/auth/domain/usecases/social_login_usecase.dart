import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/social_auth_provider.dart';
import '../entities/social_login_result.dart';
import '../repositories/auth_repository.dart';

class SocialLoginUseCase {
  const SocialLoginUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, SocialLoginResult>> call({
    required SocialAuthProvider provider,
    String? idToken,
    String? accessToken,
    String? fullName,
    String? phone,
  }) {
    return repository.socialLoginCustomer(
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
      fullName: fullName,
      phone: phone,
    );
  }
}

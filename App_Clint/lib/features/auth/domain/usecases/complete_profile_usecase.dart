import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteProfileUseCase {
  const CompleteProfileUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, User>> call({
    required String phone,
    required int cityId,
  }) {
    return repository.completeProfile(phone: phone, cityId: cityId);
  }
}

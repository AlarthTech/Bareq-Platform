import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class DeleteMyCompanyAccountUseCase {
  final AuthRepository repository;

  DeleteMyCompanyAccountUseCase(this.repository);

  Future<Either<Failure, void>> call(String password) {
    return repository.deleteMyCompanyAccount(password);
  }
}

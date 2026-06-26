import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/wallet_top_up.dart';
import '../repositories/wallet_repository.dart';

/// Dev/testing — credit wallet via bank card without payment gateway.
class TestingInstantBankCardTopUpUseCase {
  TestingInstantBankCardTopUpUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletTopUp>> call(double amount) async {
    if (amount <= 0) {
      return const Left(
        ValidationFailure('Top-up amount must be greater than zero.'),
      );
    }
    return _repository.testingInstantBankCardTopUp(amount);
  }
}

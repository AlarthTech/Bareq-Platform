import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/bank_card_top_up_start.dart';
import '../repositories/wallet_repository.dart';

class StartBankCardTopUpUseCase {
  StartBankCardTopUpUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, BankCardTopUpStart>> call(double amount) async {
    if (amount <= 0) {
      return const Left(
        ValidationFailure('Top-up amount must be greater than zero.'),
      );
    }
    return _repository.startBankCardTopUp(amount);
  }
}

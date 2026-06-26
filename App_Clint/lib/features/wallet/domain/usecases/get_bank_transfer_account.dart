import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/bank_transfer_account.dart';
import '../repositories/wallet_repository.dart';

class GetBankTransferAccountUseCase {
  GetBankTransferAccountUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, BankTransferAccount>> call() =>
      _repository.getBankTransferAccount();
}

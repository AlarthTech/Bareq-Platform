import '../../../../core/network/paged_result.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet_transaction.dart';
import '../repositories/wallet_repository.dart';

class GetWalletTransactionsUseCase {
  GetWalletTransactionsUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, PagedResult<WalletTransaction>>> call({
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getTransactions(page: page, pageSize: pageSize);
}

import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet_top_up.dart';
import '../repositories/wallet_repository.dart';

class GetTopUpStatusUseCase {
  GetTopUpStatusUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletTopUp>> call(int topUpId) =>
      _repository.getTopUpStatus(topUpId);
}

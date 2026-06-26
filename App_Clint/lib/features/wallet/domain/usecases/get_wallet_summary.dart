import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet_summary.dart';
import '../repositories/wallet_repository.dart';

class GetWalletSummaryUseCase {
  GetWalletSummaryUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletSummary>> call() => _repository.getWalletSummary();
}

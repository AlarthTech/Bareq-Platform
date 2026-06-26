import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../constants/wallet_top_up_methods.dart';
import '../entities/wallet_top_up.dart';
import '../entities/wallet_top_up_request.dart';
import '../repositories/wallet_repository.dart';

/// Bank transfer top-up only — POST /api/v1/wallet/top-up.
class CreateWalletTopUpUseCase {
  CreateWalletTopUpUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, WalletTopUp>> call(WalletTopUpRequest request) async {
    if (request.paymentMethod != WalletTopUpMethods.bankTransfer) {
      return const Left(
        ValidationFailure('Only bank transfer requests are supported.'),
      );
    }
    return _repository.createTopUp(request);
  }
}

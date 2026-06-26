import 'dart:io';

import '../../../../core/network/paged_result.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/bank_card_top_up_start.dart';
import '../entities/bank_transfer_account.dart';
import '../entities/wallet_summary.dart';
import '../entities/wallet_transaction.dart';
import '../entities/wallet_top_up.dart';
import '../entities/wallet_top_up_request.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletSummary>> getWalletSummary();

  Future<Either<Failure, PagedResult<WalletTransaction>>> getTransactions({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, BankTransferAccount>> getBankTransferAccount();

  /// POST /api/v1/wallet/top-up/bank-card — opens gateway; credits on callback.
  Future<Either<Failure, BankCardTopUpStart>> startBankCardTopUp(double amount);

  /// POST /api/v1/wallet/top-up — BankTransfer only.
  Future<Either<Failure, WalletTopUp>> createTopUp(WalletTopUpRequest request);

  Future<Either<Failure, WalletTopUp>> getTopUpStatus(int topUpId);

  Future<Either<Failure, String>> uploadReceiptImage(File file);

  /// Dev/testing — legacy bank card top-up + server/local instant credit.
  Future<Either<Failure, WalletTopUp>> testingInstantBankCardTopUp(
    double amount,
  );
}

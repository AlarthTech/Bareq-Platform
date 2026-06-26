import 'dart:io';

import '../../../../core/error/failures.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/utils/either.dart';
import '../../domain/constants/wallet_top_up_methods.dart';
import '../../domain/entities/bank_card_top_up_start.dart';
import '../../domain/entities/bank_transfer_account.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_top_up.dart';
import '../../domain/entities/wallet_top_up_request.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../wallet_testing_settings.dart';
import '../wallet_top_up_url_cache.dart';
import '../models/bank_card_top_up_start_model.dart';
import '../models/bank_transfer_account_model.dart';
import '../models/wallet_summary_model.dart';
import '../models/test_bank_card_charge_result_model.dart';
import '../models/wallet_top_up_model.dart';
import '../models/wallet_transaction_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required this.remoteDataSource,
    required this.testingSettings,
    required this.topUpUrlCache,
  });

  final WalletRemoteDataSource remoteDataSource;
  final WalletTestingSettings testingSettings;
  final WalletTopUpUrlCache topUpUrlCache;

  WalletSummary _applyTestingBonus(WalletSummary summary) {
    final bonus = testingSettings.balanceBonus;
    if (bonus <= 0) return summary;
    return summary.copyWith(
      balance: summary.balance + bonus,
      availableBalance: summary.availableBalance + bonus,
    );
  }

  @override
  Future<Either<Failure, WalletSummary>> getWalletSummary() async {
    try {
      final json = await remoteDataSource.getWalletSummary();
      final summary = WalletSummaryModel.fromJson(json);
      return Right(_applyTestingBonus(summary));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PagedResult<WalletTransaction>>> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final paged = await remoteDataSource.getTransactions(
        page: page,
        pageSize: pageSize,
      );
      final items = paged.items
          .map((json) => WalletTransactionModel.fromJson(json))
          .toList();
      return Right(
        PagedResult<WalletTransaction>(
          items: items,
          page: paged.page,
          pageSize: paged.pageSize,
          totalCount: paged.totalCount,
          totalPages: paged.totalPages,
          hasNextPage: paged.hasNextPage,
          hasPreviousPage: paged.hasPreviousPage,
        ),
      );
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankTransferAccount>> getBankTransferAccount() async {
    try {
      final json = await remoteDataSource.getBankTransferAccount();
      return Right(BankTransferAccountModel.fromJson(json));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BankCardTopUpStart>> startBankCardTopUp(
    double amount,
  ) async {
    if (amount <= 0) {
      return const Left(
        ValidationFailure('Top-up amount must be greater than zero.'),
      );
    }
    try {
      final json = await remoteDataSource.startBankCardTopUp(amount);
      final BankCardTopUpStartModel start;
      try {
        start = BankCardTopUpStartModel.fromJson(json);
      } on FormatException catch (e) {
        return Left(ServerFailure(e.message));
      }
      if (start.topUpId <= 0) {
        return const Left(ServerFailure('Invalid bank card top-up response.'));
      }
      if (start.paymentUrl.isEmpty) {
        return const Left(
          ServerFailure(
            'Payment gateway URL was not returned. The top-up will stay Pending '
            'until payment is completed or admin confirms it.',
          ),
        );
      }
      await topUpUrlCache.save(start.topUpId, start.paymentUrl);
      return Right(start);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WalletTopUp>> createTopUp(
    WalletTopUpRequest request,
  ) async {
    if (request.paymentMethod != WalletTopUpMethods.bankTransfer) {
      return const Left(
        ValidationFailure(
          'Only bank transfer top-ups use this endpoint. Use startBankCardTopUp for bank card.',
        ),
      );
    }
    if (request.requestedAmount <= 0) {
      return const Left(
        ValidationFailure('Top-up amount must be greater than zero.'),
      );
    }
    try {
      final json = await remoteDataSource.createBankTransferTopUp(request);
      return Right(WalletTopUpModel.fromJson(json));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WalletTopUp>> getTopUpStatus(int topUpId) async {
    try {
      final json = await remoteDataSource.getTopUpById(topUpId);
      return Right(WalletTopUpModel.fromJson(json));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadReceiptImage(File file) async {
    try {
      final path = await remoteDataSource.uploadReceiptImage(file);
      return Right(path);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, WalletTopUp>> testingInstantBankCardTopUp(
    double amount,
  ) async {
    if (amount <= 0) {
      return const Left(
        ValidationFailure('Top-up amount must be greater than zero.'),
      );
    }

    try {
      final json = await remoteDataSource.testInstantBankCardCharge(amount);
      final TestBankCardChargeResultModel result;
      try {
        result = TestBankCardChargeResultModel.fromJson(json);
      } on FormatException catch (e) {
        return Left(ServerFailure(e.message));
      }

      await testingSettings.clearBalanceBonus();
      await topUpUrlCache.remove(result.topUpId);

      final summaryJson = await remoteDataSource.getWalletSummary();
      final customerId = (summaryJson['customerId'] as num?)?.toInt() ?? 0;

      return Right(
        WalletTopUpModel(
          id: result.topUpId,
          customerId: customerId,
          requestedAmount: result.creditedAmount,
          approvedAmount: result.creditedAmount,
          paymentMethod: WalletTopUpMethods.bankCard,
          status: result.status,
          completedAt: DateTime.now(),
        ),
      );
    } on NotFoundFailure {
      return const Left(
        NotFoundFailure(
          'Test instant top-up is disabled on the server. Enable '
          'WalletGateway__EnableTestInstantBankCardTopUp=true on the API host.',
        ),
      );
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

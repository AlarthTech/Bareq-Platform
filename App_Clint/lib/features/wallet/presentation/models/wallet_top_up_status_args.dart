import '../../domain/entities/bank_card_top_up_start.dart';
import '../../domain/entities/wallet_top_up.dart';

/// Navigation extra for `/wallet/top-up/:id` status screen.
class WalletTopUpStatusArgs {
  const WalletTopUpStatusArgs.bankCard({
    required this.start,
    required this.amount,
  }) : topUp = null;

  const WalletTopUpStatusArgs.transfer({required this.topUp})
      : start = null,
        amount = null;

  final BankCardTopUpStart? start;
  final double? amount;
  final WalletTopUp? topUp;
}

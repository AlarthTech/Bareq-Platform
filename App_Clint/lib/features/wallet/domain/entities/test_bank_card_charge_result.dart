import 'package:equatable/equatable.dart';

/// Response from POST /api/v1/wallet/test/bank-card-charge.
class TestBankCardChargeResult extends Equatable {
  final int topUpId;
  final String status;
  final double creditedAmount;
  final double walletBalance;

  const TestBankCardChargeResult({
    required this.topUpId,
    required this.status,
    required this.creditedAmount,
    required this.walletBalance,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  @override
  List<Object?> get props =>
      [topUpId, status, creditedAmount, walletBalance];
}

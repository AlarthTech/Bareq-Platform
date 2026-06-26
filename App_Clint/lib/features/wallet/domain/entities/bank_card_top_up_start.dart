import 'package:equatable/equatable.dart';

/// Response from POST /api/v1/wallet/top-up/bank-card.
class BankCardTopUpStart extends Equatable {
  final int topUpId;
  final String paymentUrl;
  final String? message;

  const BankCardTopUpStart({
    required this.topUpId,
    required this.paymentUrl,
    this.message,
  });

  @override
  List<Object?> get props => [topUpId, paymentUrl, message];
}

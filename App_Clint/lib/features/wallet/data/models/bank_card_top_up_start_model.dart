import '../../domain/entities/bank_card_top_up_start.dart';
import '../utils/wallet_payment_url.dart';

/// Parses POST /api/v1/wallet/top-up/bank-card response (not WalletTopUpDTO).
class BankCardTopUpStartModel extends BankCardTopUpStart {
  const BankCardTopUpStartModel({
    required super.topUpId,
    required super.paymentUrl,
    super.message,
  });

  factory BankCardTopUpStartModel.fromJson(Map<String, dynamic> json) {
    final topUpId = (json['topUpId'] as num?)?.toInt();
    if (topUpId == null || topUpId <= 0) {
      throw const FormatException('Bank card top-up response missing topUpId.');
    }

    final paymentUrl = json['paymentUrl']?.toString().trim();
    if (!isWalletPaymentWebUrl(paymentUrl)) {
      throw const FormatException(
        'Bank card top-up response missing paymentUrl (http/https).',
      );
    }

    return BankCardTopUpStartModel(
      topUpId: topUpId,
      paymentUrl: paymentUrl!,
      message: json['message']?.toString(),
    );
  }
}

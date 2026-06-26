import '../../domain/entities/test_bank_card_charge_result.dart';

class TestBankCardChargeResultModel extends TestBankCardChargeResult {
  const TestBankCardChargeResultModel({
    required super.topUpId,
    required super.status,
    required super.creditedAmount,
    required super.walletBalance,
  });

  factory TestBankCardChargeResultModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim()) ?? 0;
      return 0;
    }

    final topUpId = (json['topUpId'] as num?)?.toInt();
    if (topUpId == null || topUpId <= 0) {
      throw const FormatException('Test charge response missing topUpId.');
    }

    return TestBankCardChargeResultModel(
      topUpId: topUpId,
      status: json['status']?.toString() ?? 'Completed',
      creditedAmount: parseDouble(json['creditedAmount'] ?? json['amount']),
      walletBalance: parseDouble(json['walletBalance']),
    );
  }
}

import '../../domain/entities/wallet_summary.dart';

class WalletSummaryModel extends WalletSummary {
  const WalletSummaryModel({
    required super.walletId,
    required super.customerId,
    required super.balance,
    super.reservedBalance = 0,
    required super.availableBalance,
    required super.currency,
    required super.isActive,
    required super.isWalletPaymentEnabled,
    required super.walletPaymentFeePercentage,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim()) ?? 0;
      return 0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    final balance = parseDouble(json['balance']);
    final reserved = parseDouble(json['reservedBalance']);
    final availableRaw = json['availableBalance'];
    final available = availableRaw == null
        ? (balance - reserved).clamp(0.0, double.infinity).toDouble()
        : parseDouble(availableRaw);

    return WalletSummaryModel(
      walletId: parseInt(json['walletId']),
      customerId: parseInt(json['customerId']),
      balance: balance,
      reservedBalance: reserved,
      availableBalance: available,
      currency: json['currency']?.toString() ?? 'LYD',
      isActive: json['isActive'] == true,
      isWalletPaymentEnabled: json['isWalletPaymentEnabled'] == true,
      walletPaymentFeePercentage:
          parseDouble(json['walletPaymentFeePercentage']),
    );
  }
}

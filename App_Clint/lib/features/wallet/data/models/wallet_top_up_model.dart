import '../../domain/entities/wallet_top_up.dart';
import '../utils/wallet_payment_url.dart';

class WalletTopUpModel extends WalletTopUp {
  const WalletTopUpModel({
    required super.id,
    required super.customerId,
    required super.requestedAmount,
    super.approvedAmount,
    required super.paymentMethod,
    required super.status,
    super.transferReferenceNumber,
    super.transferReceiptImageUrl,
    super.gatewayPaymentReference,
    super.paymentGatewayUrl,
    super.notes,
    super.createdAt,
    super.reviewedAt,
    super.completedAt,
  });

  factory WalletTopUpModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim()) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final text = v.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final gatewayUrl = pickWalletPaymentUrl(json);

    return WalletTopUpModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      requestedAmount: parseDouble(
        json['requestedAmount'] ?? json['amount'],
      ),
      approvedAmount: json['approvedAmount'] == null
          ? null
          : parseDouble(json['approvedAmount']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      transferReferenceNumber: json['transferReferenceNumber']?.toString(),
      transferReceiptImageUrl: json['transferReceiptImageUrl']?.toString(),
      gatewayPaymentReference: json['gatewayPaymentReference']?.toString(),
      paymentGatewayUrl: gatewayUrl?.toString(),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']),
      reviewedAt: parseDate(json['reviewedAt']),
      completedAt: parseDate(json['completedAt']),
    );
  }
}

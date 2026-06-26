import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.walletId,
    required super.customerId,
    super.bookingId,
    required super.amount,
    required super.type,
    required super.direction,
    required super.status,
    super.paymentMethod,
    super.referenceNumber,
    super.notes,
    required super.createdAt,
    super.completedAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim()) ?? 0;
      return 0;
    }

    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    int parseInt(dynamic v) => parseNullableInt(v) ?? 0;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final text = v.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return WalletTransactionModel(
      id: parseInt(json['id']),
      walletId: parseInt(json['walletId']),
      customerId: parseInt(json['customerId']),
      bookingId: parseNullableInt(json['bookingId']),
      amount: parseDouble(json['amount']),
      type: json['type']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      completedAt: parseDate(json['completedAt']),
    );
  }
}

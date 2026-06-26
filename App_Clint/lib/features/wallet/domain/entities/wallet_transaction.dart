import 'package:equatable/equatable.dart';

/// Single wallet ledger row from GET /api/v1/wallet/transactions.
class WalletTransaction extends Equatable {
  final int id;
  final int walletId;
  final int customerId;
  final int? bookingId;
  final double amount;
  final String type;
  final String direction;
  final String status;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.customerId,
    this.bookingId,
    required this.amount,
    required this.type,
    required this.direction,
    required this.status,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCredit => direction.toLowerCase() == 'credit';
  bool get isDebit => direction.toLowerCase() == 'debit';

  @override
  List<Object?> get props => [
        id,
        walletId,
        customerId,
        bookingId,
        amount,
        type,
        direction,
        status,
        paymentMethod,
        referenceNumber,
        notes,
        createdAt,
        completedAt,
      ];
}

import 'package:equatable/equatable.dart';

import '../constants/wallet_top_up_methods.dart';

/// POST /api/v1/wallet/top-up body.
class WalletTopUpRequest extends Equatable {
  final double requestedAmount;
  final String paymentMethod;
  final String? notes;
  final String? transferReferenceNumber;
  final String? transferReceiptImageUrl;

  const WalletTopUpRequest({
    required this.requestedAmount,
    required this.paymentMethod,
    this.notes,
    this.transferReferenceNumber,
    this.transferReceiptImageUrl,
  });

  factory WalletTopUpRequest.bankTransfer({
    required double requestedAmount,
    required String transferReferenceNumber,
    required String transferReceiptImageUrl,
    String? notes,
  }) {
    return WalletTopUpRequest(
      requestedAmount: requestedAmount,
      paymentMethod: WalletTopUpMethods.bankTransfer,
      transferReferenceNumber: transferReferenceNumber,
      transferReceiptImageUrl: transferReceiptImageUrl,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'requestedAmount': requestedAmount,
      'paymentMethod': paymentMethod,
    };
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
      map['notes'] = trimmedNotes;
    }
    if (paymentMethod == WalletTopUpMethods.bankTransfer) {
      map['transferReferenceNumber'] = transferReferenceNumber?.trim();
      map['transferReceiptImageUrl'] = transferReceiptImageUrl?.trim();
    }
    return map;
  }

  @override
  List<Object?> get props => [
        requestedAmount,
        paymentMethod,
        notes,
        transferReferenceNumber,
        transferReceiptImageUrl,
      ];
}

import 'package:equatable/equatable.dart';

import '../constants/wallet_top_up_methods.dart';

/// Top-up status from GET /api/v1/wallet/top-ups/{id} (or legacy top-up/{id}).
class WalletTopUp extends Equatable {
  final int id;
  final int customerId;
  final double requestedAmount;
  final double? approvedAmount;
  final String paymentMethod;
  final String status;
  final String? transferReferenceNumber;
  final String? transferReceiptImageUrl;
  final String? gatewayPaymentReference;
  final String? paymentGatewayUrl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? completedAt;

  const WalletTopUp({
    required this.id,
    required this.customerId,
    required this.requestedAmount,
    this.approvedAmount,
    required this.paymentMethod,
    required this.status,
    this.transferReferenceNumber,
    this.transferReceiptImageUrl,
    this.gatewayPaymentReference,
    this.paymentGatewayUrl,
    this.notes,
    this.createdAt,
    this.reviewedAt,
    this.completedAt,
  });

  bool get isBankCard => paymentMethod == WalletTopUpMethods.bankCard;
  bool get isBankTransfer => paymentMethod == WalletTopUpMethods.bankTransfer;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isFailed => status.toLowerCase() == 'failed';

  bool get isTerminal =>
      isCompleted || isApproved || isRejected || isFailed;

  String? get gatewayUrl {
    final url = paymentGatewayUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    final ref = gatewayPaymentReference?.trim();
    if (ref != null &&
        (ref.startsWith('http://') || ref.startsWith('https://'))) {
      return ref;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        requestedAmount,
        approvedAmount,
        paymentMethod,
        status,
        transferReferenceNumber,
        transferReceiptImageUrl,
        gatewayPaymentReference,
        paymentGatewayUrl,
        notes,
        createdAt,
        reviewedAt,
        completedAt,
      ];
}

import 'package:equatable/equatable.dart';

/// Display-only wallet payment breakdown before confirm (server recalculates on create).
class WalletBookingQuote extends Equatable {
  final double bookingTotal;
  final double walletFee;
  final double requiredAmount;
  final double walletFeePercentage;

  const WalletBookingQuote({
    required this.bookingTotal,
    required this.walletFee,
    required this.requiredAmount,
    required this.walletFeePercentage,
  });

  @override
  List<Object?> get props => [
        bookingTotal,
        walletFee,
        requiredAmount,
        walletFeePercentage,
      ];
}

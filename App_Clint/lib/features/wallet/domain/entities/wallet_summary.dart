import 'package:equatable/equatable.dart';

/// Customer wallet summary from GET /api/v1/wallet.
class WalletSummary extends Equatable {
  final int walletId;
  final int customerId;
  final double balance;
  /// Held for pending wallet bookings (not spendable).
  final double reservedBalance;
  /// Spendable balance (API: availableBalance).
  final double availableBalance;
  final String currency;
  final bool isActive;
  final bool isWalletPaymentEnabled;
  final double walletPaymentFeePercentage;

  const WalletSummary({
    required this.walletId,
    required this.customerId,
    required this.balance,
    this.reservedBalance = 0,
    required this.availableBalance,
    required this.currency,
    required this.isActive,
    required this.isWalletPaymentEnabled,
    required this.walletPaymentFeePercentage,
  });

  WalletSummary copyWith({
    double? balance,
    double? reservedBalance,
    double? availableBalance,
    bool? isActive,
    bool? isWalletPaymentEnabled,
  }) {
    return WalletSummary(
      walletId: walletId,
      customerId: customerId,
      balance: balance ?? this.balance,
      reservedBalance: reservedBalance ?? this.reservedBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      currency: currency,
      isActive: isActive ?? this.isActive,
      isWalletPaymentEnabled:
          isWalletPaymentEnabled ?? this.isWalletPaymentEnabled,
      walletPaymentFeePercentage: walletPaymentFeePercentage,
    );
  }

  @override
  List<Object?> get props => [
        walletId,
        customerId,
        balance,
        reservedBalance,
        availableBalance,
        currency,
        isActive,
        isWalletPaymentEnabled,
        walletPaymentFeePercentage,
      ];
}

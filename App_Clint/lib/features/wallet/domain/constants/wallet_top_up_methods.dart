/// API payment method values — do not use Cash or ElectronicPayment.
abstract final class WalletTopUpMethods {
  WalletTopUpMethods._();

  static const String bankCard = 'BankCard';
  static const String bankTransfer = 'BankTransfer';

  /// Booking create only.
  static const String wallet = 'Wallet';
}

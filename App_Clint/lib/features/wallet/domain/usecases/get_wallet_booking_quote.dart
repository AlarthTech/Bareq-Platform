import '../entities/wallet_booking_quote.dart';
import '../entities/wallet_summary.dart';

/// Builds a display-only wallet payment quote from server summary + price preview.
class GetWalletBookingQuoteUseCase {
  const GetWalletBookingQuoteUseCase();

  WalletBookingQuote? call({
    required WalletSummary summary,
    required double bookingTotalPrice,
  }) {
    if (!summary.isWalletPaymentEnabled || bookingTotalPrice <= 0) {
      return null;
    }
    final feePercentage = summary.walletPaymentFeePercentage;
    final walletFee = bookingTotalPrice * feePercentage / 100;
    return WalletBookingQuote(
      bookingTotal: bookingTotalPrice,
      walletFee: walletFee,
      requiredAmount: bookingTotalPrice + walletFee,
      walletFeePercentage: feePercentage,
    );
  }
}

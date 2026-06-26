/// Server-provided booking price lines (preview or stored on booking).
class BookingPriceBreakdown {
  final double servicePrice;
  final double platformFeeAmount;
  final double totalPrice;

  const BookingPriceBreakdown({
    required this.servicePrice,
    required this.platformFeeAmount,
    required this.totalPrice,
  });

  bool get hasPricing => totalPrice > 0 || servicePrice > 0;
}

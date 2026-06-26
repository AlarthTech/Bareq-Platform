import '../../domain/entities/booking_price_breakdown.dart';

class BookingPricePreviewModel {
  BookingPricePreviewModel({
    required this.servicePrice,
    required this.platformFeeAmount,
    required this.totalPrice,
  });

  final double servicePrice;
  final double platformFeeAmount;
  final double totalPrice;

  factory BookingPricePreviewModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return BookingPricePreviewModel(
      servicePrice: parseNum(json['servicePrice']),
      platformFeeAmount: parseNum(json['platformFeeAmount']),
      totalPrice: parseNum(json['totalPrice']),
    );
  }

  BookingPriceBreakdown toEntity() => BookingPriceBreakdown(
        servicePrice: servicePrice,
        platformFeeAmount: platformFeeAmount,
        totalPrice: totalPrice,
      );
}

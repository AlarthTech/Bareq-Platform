/// Input for POST /api/v1/bookings/price-preview (same shape as create, no prices).
class BookingPricePreviewParams {
  final int companyId;
  final int workerId;
  final int workTypeId;
  final DateTime bookingDate;
  final String startDate;
  final String endDate;
  final bool isMonthly;

  const BookingPricePreviewParams({
    required this.companyId,
    required this.workerId,
    required this.workTypeId,
    required this.bookingDate,
    required this.startDate,
    required this.endDate,
    required this.isMonthly,
  });
}

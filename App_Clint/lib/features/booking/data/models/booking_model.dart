import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.companyId,
    required super.companyName,
    required super.workerId,
    required super.workerName,
    required super.workerWorkTypeId,
    super.workTypeName,
    required super.bookingDate,
    super.startDate,
    super.endDate,
    super.startDateDisplay,
    super.endDateDisplay,
    required super.address,
    super.userLocationId,
    super.locationName,
    super.lat,
    super.lng,
    required super.status,
    required super.createdAt,
    super.rejectionReason,
    super.servicePrice = 0,
    super.platformFeeAmount = 0,
    super.totalPrice = 0,
    super.isMonthlyPricing = false,
    super.paymentMethod,
    super.isWorkerArrivalConfirmed = false,
    super.workerArrivalConfirmedAt,
    super.walletAmountReserved = false,
    super.walletAmountCaptured = false,
    super.walletCapturedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? fallback;
      return fallback;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseIsoDate(String? dateString) {
      if (dateString == null || dateString.isEmpty || dateString == 'string') {
        return null;
      }
      if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(dateString.trim())) {
        return null;
      }
      return CalendarDate.parseFromApi(dateString);
    }

    final startRaw = json['startDate']?.toString();
    final endRaw = json['endDate']?.toString();

    return BookingModel(
      id: parseInt(json['id'] ?? json['bookingId']),
      userId: parseInt(json['userId']),
      userName: json['userName'] as String? ?? '',
      companyId: parseInt(json['companyId']),
      companyName: json['companyName'] as String? ?? '',
      workerId: parseInt(json['workerId']),
      workerName: json['workerName'] as String? ?? '',
      workerWorkTypeId:
          parseInt(json['workerWorkTypeId'], fallback: -1) >= 0
              ? parseInt(json['workerWorkTypeId'])
              : parseInt(json['workTypeId']),
      workTypeName: json['workTypeName'] as String?,
      bookingDate: parseIsoDate(json['bookingDate'] as String?) ?? DateTime.now(),
      startDate: parseIsoDate(startRaw),
      endDate: parseIsoDate(endRaw),
      startDateDisplay: startRaw,
      endDateDisplay: endRaw,
      address: json['address'] as String? ?? '',
      userLocationId:
          json['userLocationId'] == null
              ? null
              : parseInt(json['userLocationId']),
      locationName: json['locationName'] as String?,
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      status: parseInt(json['status']),
      createdAt: parseIsoDate(json['createdAt'] as String?) ?? DateTime.now(),
      rejectionReason:
          json['rejectionReason'] as String? ??
          json['RejectionReason'] as String?,
      servicePrice: parseDouble(json['servicePrice']) ?? 0,
      platformFeeAmount: parseDouble(json['platformFeeAmount']) ?? 0,
      totalPrice: parseDouble(json['totalPrice']) ?? 0,
      isMonthlyPricing: json['isMonthlyPricing'] == true,
      paymentMethod: json['paymentMethod']?.toString(),
      isWorkerArrivalConfirmed: json['isWorkerArrivalConfirmed'] == true,
      workerArrivalConfirmedAt: parseIsoDate(
        json['workerArrivalConfirmedAt'] as String?,
      ),
      walletAmountReserved: json['walletAmountReserved'] == true,
      walletAmountCaptured: json['walletAmountCaptured'] == true,
      walletCapturedAt: parseIsoDate(json['walletCapturedAt'] as String?),
    );
  }
}

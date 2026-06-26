import '../../../../core/utils/calendar_date.dart';

/// Create-booking payload — user id comes from JWT, not the body.
class BookingRequest {
  final int companyId;
  final int workerId;
  final int workTypeId;
  final DateTime bookingDate;
  /// Shift start (e.g. `09:00`) or period start date `yyyy-MM-dd`.
  final String startDate;
  /// Shift end (e.g. `18:00`) or period end date `yyyy-MM-dd`.
  final String endDate;
  final int? userLocationId;
  final String? address;
  final bool isMonthly;
  final bool acceptedResponsibilityNotice;
  /// When set to `Wallet`, server deducts balance on create.
  final String? paymentMethod;

  const BookingRequest({
    required this.companyId,
    required this.workerId,
    required this.workTypeId,
    required this.bookingDate,
    required this.startDate,
    required this.endDate,
    this.userLocationId,
    this.address,
    this.isMonthly = false,
    this.acceptedResponsibilityNotice = false,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'companyId': companyId,
      'workerId': workerId,
      'workTypeId': workTypeId,
      'bookingDate': CalendarDate.formatForApi(bookingDate),
      'startDate': startDate,
      'endDate': endDate,
      'isMonthly': isMonthly,
      'acceptedResponsibilityNotice': acceptedResponsibilityNotice,
    };
    final method = paymentMethod?.trim();
    if (method != null && method.isNotEmpty) {
      map['paymentMethod'] = method;
    }
    if (userLocationId != null) {
      map['userLocationId'] = userLocationId;
    } else if (address != null && address!.trim().isNotEmpty) {
      map['address'] = address!.trim();
    }
    return map;
  }
}

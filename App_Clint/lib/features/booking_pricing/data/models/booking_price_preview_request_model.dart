import '../../../../core/utils/calendar_date.dart';

class BookingPricePreviewRequestModel {
  BookingPricePreviewRequestModel({
    required this.companyId,
    required this.workerId,
    required this.workTypeId,
    required this.bookingDate,
    required this.startDate,
    required this.endDate,
    required this.isMonthly,
  });

  final int companyId;
  final int workerId;
  final int workTypeId;
  final DateTime bookingDate;
  final String startDate;
  final String endDate;
  final bool isMonthly;

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'workerId': workerId,
        'workTypeId': workTypeId,
        'bookingDate': CalendarDate.formatForApi(bookingDate),
        'startDate': startDate,
        'endDate': endDate,
        'isMonthly': isMonthly,
      };
}

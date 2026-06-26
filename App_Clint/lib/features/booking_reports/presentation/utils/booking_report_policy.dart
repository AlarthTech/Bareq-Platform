import '../../../booking/domain/entities/booking_status_codes.dart';
import '../../domain/entities/booking_report.dart';

abstract final class BookingReportPolicy {
  BookingReportPolicy._();

  static const int maxReasonLength = 200;
  static const int maxDescriptionLength = 1000;

  static bool canReportBooking(int status) =>
      status == BookingStatusCodes.pending ||
      status == BookingStatusCodes.approved ||
      status == BookingStatusCodes.onTheWay ||
      status == BookingStatusCodes.rejected;

  static bool hasActiveReport(Iterable<BookingReport> reports) =>
      reports.any((report) => report.isActive);

  static String? validateReason(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'bookingReportReasonRequired';
    if (trimmed.length > maxReasonLength) {
      return 'bookingReportReasonTooLong';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.length > maxDescriptionLength) {
      return 'bookingReportDescriptionTooLong';
    }
    return null;
  }
}

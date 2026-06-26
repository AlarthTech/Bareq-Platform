import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status_codes.dart';

/// Customer-facing booking status labels (UI-only; backend codes unchanged).
abstract final class BookingCustomerStatusDisplay {
  BookingCustomerStatusDisplay._();

  static bool isCleaningStarted(Booking booking) =>
      booking.status == BookingStatusCodes.onTheWay &&
      booking.isWorkerArrivalConfirmed;

  /// L10n / badge key: `cleaning_started` or [Booking.statusString].
  static String displayStatusKey(Booking booking) {
    if (isCleaningStarted(booking)) return 'cleaning_started';
    return booking.statusString;
  }

  /// 0 = pending … 4 = completed (5-step customer timeline).
  static int customerTimelineStepIndex(Booking booking) {
    switch (booking.status) {
      case BookingStatusCodes.approved:
        return 1;
      case BookingStatusCodes.onTheWay:
        return isCleaningStarted(booking) ? 3 : 2;
      case BookingStatusCodes.completed:
        return 4;
      default:
        return 0;
    }
  }

  static const int customerTimelineStepCount = 5;

  static const List<String> customerTimelineLabelKeys = [
    'pending',
    'bookingTimelineApproved',
    'onTheWay',
    'cleaningStarted',
    'completed',
  ];

  /// Green “service in progress” step (cleaning started).
  static const int cleaningStartedTimelineStep = 3;

  static bool showCustomerTimeline(Booking booking) {
    return booking.status == BookingStatusCodes.pending ||
        booking.status == BookingStatusCodes.approved ||
        booking.status == BookingStatusCodes.onTheWay ||
        booking.status == BookingStatusCodes.completed;
  }
}

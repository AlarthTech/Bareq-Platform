/// Booking report status values (API).
class BookingReportStatus {
  BookingReportStatus._();

  static const int open = 0;
  static const int inReview = 1;
  static const int resolved = 2;
  static const int rejected = 3;

  static const String openLabel = 'مفتوح';
  static const String inReviewLabel = 'قيد المراجعة';
  static const String resolvedLabel = 'تم الحل';
  static const String rejectedLabel = 'مرفوض';

  static bool requiresNotes(int status) =>
      status == resolved || status == rejected;

  static bool isTerminal(int status) =>
      status == resolved || status == rejected;
}

/// Notification type id for new booking report submitted to company.
class BookingReportNotificationTypes {
  BookingReportNotificationTypes._();

  static const int submittedForCompany = 23;
}

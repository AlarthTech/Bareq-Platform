class NotificationTypeNames {
  NotificationTypeNames._();

  static const bookingCreated = 'BookingCreated';
  static const bookingConfirmed = 'BookingConfirmed';
  static const bookingAssigned = 'BookingAssigned';
  static const bookingInProgress = 'BookingInProgress';
  static const bookingCompleted = 'BookingCompleted';
  static const bookingCancelled = 'BookingCancelled';
  static const bookingRejected = 'BookingRejected';
  static const workerHealthCertificateExpired = 'WorkerHealthCertificateExpired';

  static const bookingReportSubmittedForCompany = 'BookingReportSubmittedForCompany';

  static const bookingTypes = {
    bookingCreated,
    bookingConfirmed,
    bookingAssigned,
    bookingInProgress,
    bookingCompleted,
    bookingCancelled,
    bookingRejected,
  };

  static bool isBooking(String? typeName) {
    if (typeName == null) return false;
    return bookingTypes.contains(typeName);
  }

  static bool isWorkerHealth(String? typeName) {
    return typeName == workerHealthCertificateExpired;
  }
}

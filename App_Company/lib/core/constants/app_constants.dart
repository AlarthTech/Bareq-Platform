class AppConstants {
  // App Info
  static const String appName = 'Bareq - companies';
  
  /// Booking statuses (API / server): 0 Pending · 1 Approved · 2 On the way ·
  /// 3 Completed · 4 Canceled · 5 Rejected.
  static const int statusPending = 0;
  static const int statusApproved = 1;
  static const int statusOnTheWay = 2;
  static const int statusCompleted = 3;
  static const int statusCanceled = 4;
  static const int statusRejected = 5;

  static const String statusPendingText = 'قيد الانتظار';
  static const String statusApprovedText = 'مقبول';
  static const String statusOnTheWayText = 'في الطريق';
  static const String statusCleaningStartedText = 'بدأت عملية التنظيف';
  static const String statusCleaningStartedTextEn = 'Cleaning Started';
  static const String statusCompletedText = 'مكتمل';
  static const String statusCanceledText = 'ملغى';
  static const String statusRejectedText = 'مرفوض';

  /// Terminal: completed, canceled, or rejected — no further company actions.
  static bool isBookingTerminal(int status) =>
      status == statusCompleted || status == statusCanceled || status == statusRejected;

  /// UI-only: OnTheWay + customer confirmed worker arrival (backend status stays 2).
  static bool isCleaningStartedDisplay({
    required int status,
    required bool isWorkerArrivalConfirmed,
  }) =>
      status == statusOnTheWay && isWorkerArrivalConfirmed;

  /// Blocks worker availability: pending, approved, or on the way.
  static bool isBookingBlockingWorker(int status) =>
      status == statusPending || status == statusApproved || status == statusOnTheWay;

  /// Active pipeline (non-terminal, pre-completion).
  static bool isBookingInPipeline(int status) => !isBookingTerminal(status);

  /// Canceled or rejected (for list/dashboard “ملغاة” bucket).
  static bool isBookingCanceledOrRejected(int status) =>
      status == statusCanceled || status == statusRejected;
  
  // Currency
  static const String currency = 'د.ل';
  static const String currencyRevenue = 'ر.س';
  
  // Health Certificate
  static const int healthCertificateWarningDays = 30;
  static const int healthCertificateUrgentDays = 7;
  static const int healthCertificateExpiredDays = -7;
  
  // Booking Alerts
  static const int bookingAlertHours = 24;
  
  // User Types
  /// Company owner user type in API (`UserTypes` table — Company = 1).
  static const int userTypeCompany = 1;
  
  // Overnight Status
  static const String overnightText = 'مبيت';
  static const String notOvernightText = 'بدون مبيت';
  
  // Storage Keys
  static const String userKey = 'user';
  static const String tokenKey = 'token';
  static const String companyKey = 'company';
  static const String companyIdKey = 'company_id';
  
  // Pagination
  static const int defaultPageSize = 20;

  // Worker form (aligned with API minimum age 18)
  static const int workerMinAge = 18;
  static const int workerMaxAge = 60;
}

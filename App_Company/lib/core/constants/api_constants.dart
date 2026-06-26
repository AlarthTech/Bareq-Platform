class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://apialbareq.al-earth.ly';
  
  // API Endpoints
  static const String apiPrefix = '/api';
  
  // Authentication
  static const String login = '$apiPrefix/AppUsers/Login';
  static const String changePassword = '$apiPrefix/AppUsers/ChangePassword';
  static const String changePersonalInfo = '$apiPrefix/AppUsers/ChangePersonalInfo';
  static const String changePhoneNumber = '$apiPrefix/AppUsers/ChangePhoneNumber';
  static const String register = '$apiPrefix/AppUsers/CreateNewCompanyOwner';
  static const String forgotPassword = '$apiPrefix/AppUsers/ForgotPassword';
  static const String verifyResetCode = '$apiPrefix/AppUsers/VerifyResetCode';
  static const String resetPassword = '$apiPrefix/AppUsers/ResetPassword';
  static const String deleteMyCompanyAccount =
      '$apiPrefix/AppUsers/DeleteMyCompanyAccount';
  
  // Company
  static const String getMyCompany = '$apiPrefix/Companies/GetMyCompanyByIdUser';
  static const String createCompany = '$apiPrefix/Companies/CreateCompany';
  static String updateCompany(int companyId) =>
      '$apiPrefix/Companies/UpdateCompany/$companyId';
  static String uploadCommercialRegister(int companyId) =>
      '$apiPrefix/Companies/UploadCommercialRegister/$companyId';
  
  // Workers
  static const String getWorkersByCompany = '$apiPrefix/Workers/Company';
  static const String createWorker = '$apiPrefix/Workers/CreateWorker';
  static String updateWorker(int workerId) =>
      '$apiPrefix/Workers/UpdateWorker/$workerId';
  static String uploadHealthCertificate(int workerId) =>
      '$apiPrefix/Workers/UploadHealthCertificate/$workerId';
  
  // Work Types
  static const String getWorkTypesByCompany = '$apiPrefix/WorkTypes/GetWorkTypesByCompany';
  static const String getWorkTypeById = '$apiPrefix/WorkTypes/GetWorkTypeById';
  static const String createWorkType = '$apiPrefix/WorkTypes/CreateWorkType';
  static const String updateWorkType = '$apiPrefix/WorkTypes/UpdateWorkType';
  static const String deleteWorkType = '$apiPrefix/WorkTypes/DeleteWorkType';
  static const String assignWorkTypeToWorker = '$apiPrefix/WorkTypes/AssignWorkTypeToWorker';
  static const String getWorkerWorkTypes = '$apiPrefix/WorkTypes/GetWorkerWorkTypes';
  
  // Bookings
  static const String getBookingsByCompany = '$apiPrefix/Bookings/Company';
  static const String getBookingById = '$apiPrefix/Bookings/GetBookingById';
  static const String updateBookingStatus = '$apiPrefix/Bookings/UpdateStatusBooking';
  
  // Supporting Data
  static const String getAllCities = '$apiPrefix/Cities/GetAllCities';
  static const String getNationalities = '$apiPrefix/Nationalities/GetNationalities';
  static const String getAllLanguages = '$apiPrefix/Languages/GetAllLanguages';

  // Notifications
  static const String notificationsHub = '/hubs/notifications';
  static const String getMyNotifications = '$apiPrefix/Notifications/GetMyNotifications';
  static const String getUnreadCount = '$apiPrefix/Notifications/GetUnreadCount';
  static String markNotificationAsRead(int id) =>
      '$apiPrefix/Notifications/MarkAsRead/$id';
  static const String markAllNotificationsAsRead =
      '$apiPrefix/Notifications/MarkAllAsRead';
  static String deleteNotification(int id) =>
      '$apiPrefix/Notifications/DeleteNotification/$id';

  // Reviews & Ratings
  static String companyRatingSummary(int companyId) =>
      '$apiPrefix/Reviews/Company/$companyId/Summary';
  static String companyWorkerRatingSummaries(int companyId) =>
      '$apiPrefix/Reviews/Company/$companyId/WorkerSummaries';
  static String workerRatingSummary(int workerId) =>
      '$apiPrefix/Reviews/Worker/$workerId/Summary';
  static String workerReviews(int workerId) =>
      '$apiPrefix/Reviews/Worker/$workerId';
  static String getReviewById(int id) => '$apiPrefix/Reviews/GetReviewById/$id';

  // Booking Reports (company owner — view & resolve customer reports)
  static const String bookingReports = '$apiPrefix/BookingReports';
  static String bookingReportById(int id) => '$apiPrefix/BookingReports/$id';
  static String updateBookingReportStatus(int id) =>
      '$apiPrefix/BookingReports/$id/Status';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  /// Create company / file uploads can be slow on the current server.
  static const Duration longRunningReceiveTimeout = Duration(seconds: 90);
  static const Duration longRunningSendTimeout = Duration(seconds: 90);
}

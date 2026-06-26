/// API endpoints constants
/// All API endpoints should be defined here for easy management
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = 'https://apialbareq.al-earth.ly';

  // Auth endpoints
  static const String createCustomer = '/api/AppUsers/CreateNewCustomer';
  static const String login = '/api/AppUsers/Login';
  static const String socialLoginCustomer = '/api/AppUsers/SocialLoginCustomer';
  static const String forgotPassword = '/api/AppUsers/ForgotPassword';
  static const String verifyResetCode = '/api/AppUsers/VerifyResetCode';
  static const String resetPassword = '/api/AppUsers/ResetPassword';

  // Reports (customer JWT)
  static const String createReport = '/api/Reports/CreateReport';
  static const String getMyReports = '/api/Reports/GetMyReports';
  static String getReportById(int id) => '/api/Reports/GetReportById/$id';
  static String deleteReport(int id) => '/api/Reports/DeleteReport/$id';

  // Booking reports (customer JWT)
  static const String createBookingReport = '/api/BookingReports';
  static const String myBookingReports = '/api/BookingReports/MyReports';
  static String bookingReportsByBookingId(int bookingId) =>
      '/api/BookingReports/Booking/$bookingId';
  static const String logout = '/api/auth/logout';

  // Cities endpoints
  static const String getAllCities = '/api/Cities/GetAllCities';

  // Languages endpoints
  static const String getAllLanguages = '/api/Languages/GetAllLanguages';

  // Home endpoints
  static const String homeData = '/api/home';
  static const String availableMaids = '/api/maids/available';

  // Workers — customer browse (`companyId` query filters by company on Available).
  /// `date`, `companyId`, `page`, `pageSize` query params.
  static const String workersAvailableByDate = '/api/Workers/Available';
  /// v1 customer browse — anonymous, rate-limited.
  static const String workersAvailableV1 = '/api/v1/workers/available';
  static const String workersTopRatedV1 = '/api/v1/workers/top-rated';
  /// Company-scoped list; requires company/admin role — customer app uses Available?companyId= instead.
  static String getWorkersByCompany(int companyId) =>
      '/api/Workers/Company/$companyId';
  static String getWorkerById(int id) => '/api/Workers/GetWorkerById/$id';

  // Companies endpoints
  static const String getAllCompanies = '/api/Companies/GetisVerifiedCompanies';
  static String getCompanyById(int id) => '/api/Companies/GetCompanyById/$id';

  // Maid endpoints
  static const String maids = '/api/maids';
  static String maidDetails(String id) => '$maids/$id';

  // Booking endpoints
  static const String bookings = '/api/bookings';
  static String bookingDetails(String id) => '$bookings/$id';
  static String getUserBookings(int userId) => '/api/Bookings/User/$userId';
  static String getCompanyBookings(int companyId) =>
      '/api/Bookings/Company/$companyId';
  static String updateBookingStatus(int bookingId) =>
      '/api/Bookings/UpdateStatusBooking/$bookingId';
  static String getWorkerWorkTypes(int workerId) =>
      '/api/WorkTypes/GetWorkerWorkTypes/$workerId';
  static String getWorkTypesByCompany(int companyId) =>
      '/api/WorkTypes/GetWorkTypesByCompany/$companyId';
  static const String getAllWorkTypes = '/api/WorkTypes/GetAllWorkTypes';
  static const String createBooking = '/api/Bookings/CreateBooking';
  static String confirmBookingArrival(int bookingId) =>
      '/api/Bookings/$bookingId/ConfirmArrival';
  static const String bookingPricePreview = '/api/v1/bookings/price-preview';

  // Wallet (customer JWT)
  static const String walletSummary = '/api/v1/wallet';
  static const String walletTransactions = '/api/v1/wallet/transactions';
  static const String walletBankTransferAccount =
      '/api/v1/wallet/bank-transfer-account';
  static const String walletTopUp = '/api/v1/wallet/top-up';
  static const String walletBankCardTopUp = '/api/v1/wallet/top-up/bank-card';
  static String walletTopUpStatus(int id) => '/api/v1/wallet/top-ups/$id';

  /// Legacy status path (fallback when top-ups route is unavailable).
  static String walletTopUpById(int id) => '/api/v1/wallet/top-up/$id';

  /// Test-only instant bank card credit (customer JWT; 404 when disabled on server).
  static const String walletTestBankCardCharge =
      '/api/v1/wallet/test/bank-card-charge';

  /// Receipt image upload — returns relative path (e.g. /Uploads/receipt.jpg).
  static const String uploadFile = '/api/Uploads/Upload';
  static String updateBooking(int id) => '/api/Bookings/UpdateBooking/$id';

  // Reviews
  static const String createReview = '/api/Reviews/CreateReview';
  static String updateReview(int id) => '/api/Reviews/UpdateReview/$id';
  static String deleteReview(int id) => '/api/Reviews/DeleteReview/$id';
  static String reviewsByWorker(int workerId) =>
      '/api/Reviews/Worker/$workerId';
  static String reviewsByBooking(int bookingId) =>
      '/api/Reviews/Booking/$bookingId';
  static String getReviewById(int id) => '/api/Reviews/GetReviewById/$id';
  static String workerRatingSummary(int workerId) =>
      '/api/Reviews/Worker/$workerId/Summary';
  static String companyRatingSummary(int companyId) =>
      '/api/Reviews/Company/$companyId/Summary';
  static String companyWorkerRatingSummaries(int companyId) =>
      '/api/Reviews/Company/$companyId/WorkerSummaries';

  // Notifications (customer JWT)
  static const String getMyNotifications =
      '/api/Notifications/GetMyNotifications';
  static const String getUnreadCount = '/api/Notifications/GetUnreadCount';
  static String markNotificationAsRead(int id) =>
      '/api/Notifications/MarkAsRead/$id';
  static const String markAllNotificationsAsRead =
      '/api/Notifications/MarkAllAsRead';
  static String deleteNotification(int id) =>
      '/api/Notifications/DeleteNotification/$id';

  /// Legacy — prefer [createReview].
  static const String submitReview = '/api/Reviews';

  // App Users endpoints
  static const String getAllAppUsers = '/api/AppUsers/GetAllAppUsers';
  static const String changePassword = '/api/AppUsers/ChangePassword';
  static const String changePersonalInfo = '/api/AppUsers/ChangePersonalInfo';
  static const String changePhoneNumber = '/api/AppUsers/ChangePhoneNumber';
  static String deleteAppUser(int id) => '/api/AppUsers/DeleteAppUser/$id';

  // User locations
  static const String getMyLocations = '/api/UserLocations/GetMyLocations';
  static String getUserLocationById(int id) =>
      '/api/UserLocations/GetUserLocationById/$id';
  static const String createUserLocation =
      '/api/UserLocations/CreateUserLocation';
  static String updateUserLocation(int id) =>
      '/api/UserLocations/UpdateUserLocation/$id';
  static String deleteUserLocation(int id) =>
      '/api/UserLocations/DeleteUserLocation/$id';

  // When you add create-company: JWT role `Company` omits `ownerUserId` (server sets owner);
  // role `Admin` sends `ownerUserId` as required by the API.
}

/// Central route paths for [GoRouter] and [AppBottomNavBar] — use these with
/// `context.go(...)` so the bottom bar and router never drift apart.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordVerify = '/forgot-password/verify';
  static const String forgotPasswordReset = '/forgot-password/reset';
  /// Resend OTP — pre-fill email on step 1.
  static String forgotPasswordWithEmail(String email) =>
      Uri(
        path: forgotPassword,
        queryParameters: {'email': email},
      ).toString();

  static String forgotPasswordVerifyRoute(String email) =>
      Uri(
        path: forgotPasswordVerify,
        queryParameters: {'email': email},
      ).toString();

  static const String createCompany = '/create-company';
  static const String addCompany = '/companies/add';
  static const String companies = '/companies';
  static String editCompany(int companyId) => '/companies/edit/$companyId';
  static const String onboardingSuccess = '/onboarding-success';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String deleteAccount = '/profile/delete-account';
  /// Legacy alias — redirects to [profile].
  static const String accountSettings = '/settings';
  static const String bookings = '/bookings';

  /// Full-screen booking detail — pass [BookingDetailExtra] as `extra` when pushing.
  static String bookingDetail(int bookingId) => '/bookings/detail/$bookingId';

  /// Opens bookings tab filtered by [status] (see [AppConstants] status values).
  static String bookingsWithStatus(int status) =>
      Uri(path: bookings, queryParameters: {'status': '$status'}).toString();

  /// Approved + on-the-way (dashboard “جارية”).
  static String bookingsOngoing() =>
      Uri(path: bookings, queryParameters: {'filter': 'ongoing'}).toString();
  static const String workers = '/workers';
  static const String workersAdd = '/workers/add';
  static const String workTypes = '/work-types';
  static const String workTypesAdd = '/work-types/add';

  /// Detail route — pass [WorkerEntity] as `extra` when pushing.
  static String workerDetail(int workerId) => '/workers/$workerId';

  static const String notifications = '/notifications';

  static const String ratings = '/ratings';

  static String workerReviews(int workerId) => '/workers/$workerId/reviews';

  static String reviewDetail(int reviewId) => '/reviews/$reviewId';

  static const String companyBookingReports = '/company/booking-reports';

  static String companyBookingReportDetail(int reportId) =>
      '/company/booking-reports/$reportId';

  /// Bottom nav: 0 dashboard · 1 bookings · 2 workers · 3 work-types · 4 profile
  static const int navDashboard = 0;
  static const int navBookings = 1;
  static const int navWorkers = 2;
  static const int navWorkTypes = 3;
  static const int navProfile = 4;
}

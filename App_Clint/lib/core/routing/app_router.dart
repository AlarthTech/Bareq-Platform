import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/complete_profile_screen.dart';
import '../../features/auth/presentation/pages/registration_screen.dart';
import '../../features/forgot_password/presentation/pages/forgot_password_screen.dart';
import '../../features/forgot_password/presentation/pages/verify_reset_code_screen.dart';
import '../../features/forgot_password/presentation/pages/reset_password_screen.dart';
import '../../features/reports/presentation/pages/create_report_page.dart';
import '../../features/reports/presentation/pages/my_reports_page.dart';
import '../../features/reports/presentation/pages/report_detail_page.dart';
import '../../features/reports/presentation/models/create_report_args.dart';
import '../../features/reports/domain/entities/report.dart';
import '../../features/booking_reports/presentation/pages/booking_report_detail_page.dart';
import '../../features/booking_reports/presentation/pages/booking_reports_by_booking_page.dart';
import '../../features/booking_reports/presentation/pages/create_booking_report_page.dart';
import '../../features/booking_reports/presentation/pages/my_booking_reports_page.dart';
import '../../features/booking_reports/presentation/models/create_booking_report_args.dart';
import '../../features/booking_reports/domain/entities/booking_report.dart';
import '../../features/reviews/presentation/pages/rate_worker_page.dart';
import '../../features/reviews/presentation/pages/my_review_page.dart';
import '../../features/reviews/presentation/models/rate_worker_args.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/search/presentation/pages/search_screen.dart';
import '../../features/search/presentation/pages/search_results_screen.dart';
import '../../features/companies/presentation/pages/companies_screen.dart';
import '../../features/booking/presentation/pages/bookings_screen.dart';
import '../../features/favorites/presentation/pages/favorites_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/wallet/domain/entities/wallet_top_up.dart';
import '../../features/wallet/presentation/models/wallet_top_up_status_args.dart';
import '../../features/wallet/presentation/pages/wallet_screen.dart';
import '../../features/wallet/presentation/pages/wallet_bank_transfer_top_up_screen.dart';
import '../../features/wallet/presentation/pages/wallet_top_up_screen.dart';
import '../../features/wallet/presentation/pages/wallet_top_up_status_screen.dart';
import '../../features/wallet/presentation/pages/wallet_transactions_screen.dart';
import '../../features/profile/presentation/pages/settings/edit_profile_screen.dart';
import '../../features/profile/presentation/pages/settings/notifications_settings_screen.dart';
import '../../features/profile/presentation/pages/settings/privacy_security_screen.dart';
import '../../features/profile/presentation/pages/settings/change_phone_screen.dart';
import '../../features/profile/presentation/pages/settings/change_password_screen.dart';
import '../../features/profile/presentation/pages/settings/help_support_screen.dart';
import '../../features/profile/presentation/pages/settings/terms_conditions_screen.dart';
import '../../features/profile/presentation/pages/settings/about_bareq_screen.dart';
import '../../features/profile/presentation/pages/settings/privacy_policy_screen.dart';
import '../../features/legal/presentation/registration_legal_read_tracker.dart';
import '../../features/company/presentation/pages/company_home_screen.dart';
import '../../features/user_locations/domain/entities/user_location.dart';
import '../../features/user_locations/presentation/pages/saved_locations_screen.dart';
import '../../features/user_locations/presentation/pages/add_edit_location_screen.dart';
import '../../features/maid/presentation/pages/maid_details_screen.dart';
import '../../features/companies/presentation/pages/company_details_screen.dart';
import '../../features/booking/presentation/pages/booking_screen.dart';
import '../../features/booking/presentation/pages/booking_details_screen.dart';
import '../../features/auth/domain/entities/app_user_role.dart';
import '../auth/auth_session_notifier.dart';
import '../constants/app_strings.dart';
import 'custom_page_transitions.dart';

/// App router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static late final GoRouter router;

  static void configure({required AuthSessionNotifier authSession}) {
    router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppStrings.routeSplash,
      refreshListenable: authSession,
      redirect: (context, state) =>
          _redirect(authSession: authSession, state: state),
      routes: [
        GoRoute(
          path: AppStrings.routeSplash,
          name: 'splash',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const SplashScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeLogin,
          name: 'login',
          pageBuilder: (context, state) =>
              CustomPageTransitions.scaleFadeTransition(
                const LoginScreen(),
                state,
              ),
        ),
        GoRoute(
          path: AppStrings.routeCompleteProfile,
          name: 'complete-profile',
          pageBuilder: (context, state) =>
              CustomPageTransitions.scaleFadeTransition(
                const CompleteProfileScreen(),
                state,
              ),
        ),
        GoRoute(
          path: AppStrings.routeRegistration,
          name: 'registration',
          pageBuilder: (context, state) =>
              CustomPageTransitions.scaleFadeTransition(
                const RegistrationScreen(),
                state,
              ),
        ),
        GoRoute(
          path: AppStrings.routeForgotPassword,
          name: 'forgot-password',
          pageBuilder: (context, state) =>
              CustomPageTransitions.scaleFadeTransition(
                const ForgotPasswordScreen(),
                state,
              ),
        ),
        GoRoute(
          path: AppStrings.routeVerifyResetCode,
          name: 'verify-reset-code',
          pageBuilder: (context, state) =>
              CustomPageTransitions.scaleFadeTransition(
                const VerifyResetCodeScreen(),
                state,
              ),
        ),
        GoRoute(
          path: AppStrings.routeResetPassword,
          name: 'reset-password',
          pageBuilder: (context, state) =>
              CustomPageTransitions.scaleFadeTransition(
                const ResetPasswordScreen(),
                state,
              ),
        ),
        GoRoute(
          path: AppStrings.routeHome,
          name: 'home',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const HomeScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeAdminHome,
          name: 'admin-home',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const _RoleDashboardScreen(
              title: 'Admin',
              subtitle: 'Admin tools and approvals will appear here.',
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeCompanyHome,
          name: 'company-home',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const CompanyHomeScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeSearch,
          name: 'search',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CustomPageTransitions.fadeTransition(
              SearchScreen(
                selectedDate: extra?['selectedDate'] as DateTime?,
                initialMinRating: extra?['initialMinRating'] as double?,
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeCompanies,
          name: 'companies',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const CompaniesScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeSearchResults,
          name: 'search-results',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            return CustomPageTransitions.fadeTransition(
              SearchResultsScreen(
                searchQuery: extra?['searchQuery'] as String?,
                bookingDate: extra?['bookingDate'] as DateTime?,
                selectedLanguages: extra?['selectedLanguages'] as Set<String>?,
                selectedNationalities:
                    extra?['selectedNationalities'] as Set<String>?,
                minRating: extra?['minRating'] as double?,
                minExperience: extra?['minExperience'] as int?,
                selectedCity: extra?['selectedCity'] as String?,
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeBookings,
          name: 'bookings',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const BookingsScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeFavorites,
          name: 'favorites',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const FavoritesScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeProfile,
          name: 'profile',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const ProfileScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeWallet,
          name: 'wallet',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            WalletScreen(
              refreshToken: state.uri.queryParameters['refresh'],
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeWalletTopUp,
          name: 'wallet-top-up',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const WalletTopUpScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeWalletBankTransferTopUp,
          name: 'wallet-bank-transfer-top-up',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const WalletBankTransferTopUpScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeWalletTransactions,
          name: 'wallet-transactions',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const WalletTransactionsScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeWalletTopUpStatus,
          name: 'wallet-top-up-status',
          pageBuilder: (context, state) {
            WalletTopUpStatusArgs? args;
            WalletTopUp? topUp;
            if (state.extra is WalletTopUpStatusArgs) {
              args = state.extra! as WalletTopUpStatusArgs;
            } else if (state.extra is WalletTopUp) {
              topUp = state.extra! as WalletTopUp;
            }
            final topUpId = args?.start?.topUpId.toString() ??
                topUp?.id.toString() ??
                state.pathParameters['id'] ??
                '';
            return CustomPageTransitions.fadeTransition(
              WalletTopUpStatusScreen(
                topUpId: topUpId,
                initialStart: args?.start,
                initialAmount: args?.amount,
                initialTopUp: args?.topUp ?? topUp,
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeEditProfile,
          name: 'edit-profile',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const EditProfileScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeNotificationsSettings,
          name: 'notifications-settings',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const NotificationsSettingsScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routePrivacySecurity,
          name: 'privacy-security',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const PrivacySecurityScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeChangePhone,
          name: 'change-phone',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const ChangePhoneScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeChangePassword,
          name: 'change-password',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const ChangePasswordScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeHelpSupport,
          name: 'help-support',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const HelpSupportScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeAboutBareq,
          name: 'about-bareq',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const AboutBareqScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routePrivacyPolicy,
          name: 'privacy-policy',
          pageBuilder: (context, state) {
            final tracker = state.extra is RegistrationLegalReadTracker
                ? state.extra! as RegistrationLegalReadTracker
                : null;
            return CustomPageTransitions.fadeTransition(
              PrivacyPolicyScreen(registrationReadTracker: tracker),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeTermsConditions,
          name: 'terms-conditions',
          pageBuilder: (context, state) {
            final tracker = state.extra is RegistrationLegalReadTracker
                ? state.extra! as RegistrationLegalReadTracker
                : null;
            return CustomPageTransitions.fadeTransition(
              TermsConditionsScreen(registrationReadTracker: tracker),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeSavedLocations,
          name: 'saved-locations',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const SavedLocationsScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeAddLocation,
          name: 'add-location',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const AddEditLocationScreen(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeEditLocation,
          name: 'edit-location',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            AddEditLocationScreen(
              existing: state.extra as UserLocation?,
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeMaidDetails,
          name: 'maid-details',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            MaidDetailsScreen(
              maidId: state.pathParameters['id']!,
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeCompanyDetails,
          name: 'company-details',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            CompanyDetailsScreen(
              companyId: state.pathParameters['id']!,
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeBooking,
          name: 'booking',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            BookingScreen(
              maidId: state.pathParameters['maidId']!,
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeBookingDetails,
          name: 'booking-details',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            BookingDetailsScreen(
              bookingId: state.pathParameters['bookingId']!,
            ),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeCreateReport,
          name: 'create-report',
          pageBuilder: (context, state) {
            final args = state.extra as CreateReportArgs?;
            return CustomPageTransitions.fadeTransition(
              CreateReportPage(
                args:
                    args ??
                    const CreateReportArgs(
                      targetType: ReportTargetType.worker,
                      targetId: 0,
                      targetName: '',
                    ),
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeMyReports,
          name: 'my-reports',
          pageBuilder: (context, state) {
            final returnRoute = state.extra as String?;
            return CustomPageTransitions.fadeTransition(
              MyReportsPage(returnRoute: returnRoute),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeReportDetail,
          name: 'report-detail',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return CustomPageTransitions.fadeTransition(
              ReportDetailPage(reportId: id),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeCreateBookingReport,
          name: 'create-booking-report',
          pageBuilder: (context, state) {
            final args = state.extra as CreateBookingReportArgs?;
            return CustomPageTransitions.fadeTransition(
              CreateBookingReportPage(
                args:
                    args ??
                    const CreateBookingReportArgs(
                      bookingId: 0,
                      bookingLabel: '',
                      bookingStatus: 0,
                    ),
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeMyBookingReports,
          name: 'my-booking-reports',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const MyBookingReportsPage(),
            state,
          ),
        ),
        GoRoute(
          path: AppStrings.routeBookingReportsByBooking,
          name: 'booking-reports-by-booking',
          pageBuilder: (context, state) {
            final bookingId =
                int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;
            return CustomPageTransitions.fadeTransition(
              BookingReportsByBookingPage(bookingId: bookingId),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeBookingReportDetail,
          name: 'booking-report-detail',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final initialReport = state.extra as BookingReport?;
            return CustomPageTransitions.fadeTransition(
              BookingReportDetailPage(
                reportId: id,
                initialReport: initialReport,
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeRateWorker,
          name: 'rate-worker',
          pageBuilder: (context, state) {
            final args = state.extra as RateWorkerArgs?;
            return CustomPageTransitions.fadeTransition(
              RateWorkerPage(
                args: args ??
                    const RateWorkerArgs(
                      bookingId: 0,
                      workerId: 0,
                      workerName: '',
                      companyId: 0,
                    ),
              ),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeMyReview,
          name: 'my-review',
          pageBuilder: (context, state) {
            final bookingId =
                int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;
            return CustomPageTransitions.fadeTransition(
              MyReviewPage(bookingId: bookingId),
              state,
            );
          },
        ),
        GoRoute(
          path: AppStrings.routeNotifications,
          name: 'notifications',
          pageBuilder: (context, state) => CustomPageTransitions.fadeTransition(
            const NotificationsPage(),
            state,
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Error: ${state.error ?? 'Unknown error'}'),
        ),
      ),
    );
  }

  static String? _redirect({
    required AuthSessionNotifier authSession,
    required GoRouterState state,
  }) {
    final loc = state.matchedLocation;
    final loggedIn = authSession.isLoggedIn;
    final role = authSession.role;

    if (_requiresCustomerAuth(loc)) {
      if (!loggedIn) return AppStrings.routeLogin;
      if (role != null &&
          role != AppUserRole.customer) {
        return authSession.postAuthHomeRoute;
      }
    }

    if (loggedIn && authSession.requiresProfileCompletion) {
      final isLogout = loc == AppStrings.routeLogin;
      if (!isLogout && loc != AppStrings.routeCompleteProfile) {
        return AppStrings.routeCompleteProfile;
      }
    }

    if (loc == AppStrings.routeAdminHome) {
      if (!loggedIn) return AppStrings.routeLogin;
      if (role != AppUserRole.admin) return AppStrings.routeHome;
    }

    if (loc == AppStrings.routeCompanyHome) {
      if (!loggedIn) return AppStrings.routeLogin;
      if (role != AppUserRole.company) return AppStrings.routeHome;
    }

    if (loggedIn &&
        authSession.requiresProfileCompletion &&
        (loc == AppStrings.routeLogin ||
            loc == AppStrings.routeRegistration ||
            loc == AppStrings.routeForgotPassword ||
            loc == AppStrings.routeVerifyResetCode ||
            loc == AppStrings.routeResetPassword)) {
      return AppStrings.routeCompleteProfile;
    }

    if (loggedIn &&
        !authSession.requiresProfileCompletion &&
        (loc == AppStrings.routeLogin ||
            loc == AppStrings.routeRegistration ||
            loc == AppStrings.routeForgotPassword ||
            loc == AppStrings.routeVerifyResetCode ||
            loc == AppStrings.routeResetPassword)) {
      return authSession.postAuthHomeRoute;
    }

    return null;
  }

  /// Customer-only flows (bookings, profile, create/view booking).
  static bool _requiresCustomerAuth(String loc) {
    // Legal pages are public (e.g. readable during registration before login).
    if (loc == AppStrings.routeTermsConditions ||
        loc == AppStrings.routePrivacyPolicy) {
      return false;
    }
    if (loc == AppStrings.routeBookings) return true;
    if (loc == AppStrings.routeProfile) return true;
    if (loc.startsWith('/profile/')) return true;
    if (loc.startsWith('/booking-details')) return true;
    if (loc.startsWith('/booking/')) return true;
    if (loc.startsWith('/reports')) return true;
    if (loc.startsWith('/booking-reports')) return true;
    if (loc.startsWith('/reviews')) return true;
    if (loc == AppStrings.routeNotifications) return true;
    return false;
  }
}

class _RoleDashboardScreen extends StatelessWidget {
  const _RoleDashboardScreen({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title — Bareq')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

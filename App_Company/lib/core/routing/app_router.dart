import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/delete_account_screen.dart';
import '../../features/auth/presentation/bloc/account_settings_cubit.dart';
import '../../features/auth/presentation/bloc/delete_account_cubit.dart';
import '../../features/bookings/presentation/bloc/booking_detail_cubit.dart';
import '../../features/bookings/domain/usecases/get_booking_by_id_usecase.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/bookings/presentation/screens/bookings_list_screen.dart';
import '../../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../../features/bookings/presentation/models/booking_detail_extra.dart';
import '../../features/workers/presentation/screens/workers_list_screen.dart';
import '../../features/workers/presentation/screens/add_worker_screen.dart';
import '../../features/workers/presentation/screens/worker_detail_screen.dart';
import '../../features/workers/presentation/models/worker_detail_extra.dart';
import '../../features/workers/domain/entities/worker_entity.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/state/notifications_cubit.dart';
import '../../features/worker_reviews/presentation/pages/company_ratings_page.dart';
import '../../features/worker_reviews/presentation/pages/worker_reviews_page.dart';
import '../../features/worker_reviews/presentation/pages/review_detail_page.dart';
import '../../features/worker_reviews/presentation/state/company_ratings_cubit.dart';
import '../../features/worker_reviews/presentation/state/worker_reviews_cubit.dart';
import '../../features/worker_reviews/presentation/widgets/review_list_item.dart';
import '../../features/booking_reports/presentation/pages/company_booking_reports_page.dart';
import '../../features/booking_reports/presentation/pages/booking_report_detail_page.dart';
import '../../features/booking_reports/presentation/state/company_booking_reports_cubit.dart';
import '../../features/booking_reports/presentation/state/booking_report_detail_cubit.dart';
import '../../features/booking_reports/presentation/state/update_booking_report_status_cubit.dart';
import '../../features/work_types/presentation/screens/work_types_list_screen.dart';
import '../../features/work_types/presentation/screens/add_work_type_screen.dart';
import '../../features/company/presentation/screens/create_company_screen.dart';
import '../../features/company/presentation/screens/companies_management_screen.dart';
import '../../features/company/presentation/screens/edit_company_entry_screen.dart';
import '../../features/company/presentation/screens/onboarding_success_screen.dart';
import '../../features/company/presentation/models/company_form_mode.dart';
import '../../features/company/domain/entities/company_entity.dart';
import '../../features/company/presentation/models/edit_company_route_extra.dart';
import '../../features/company/presentation/models/onboarding_success_extra.dart';
import '../../features/company/presentation/cubit/company_guard_cubit.dart';
import '../../features/forgot_password/presentation/pages/forgot_password_page.dart';
import '../../features/forgot_password/presentation/pages/verify_otp_page.dart';
import '../../features/forgot_password/presentation/pages/reset_password_page.dart';
import '../../features/forgot_password/presentation/models/forgot_password_reset_extra.dart';
import '../constants/app_routes.dart';
import '../di/injection.dart';
import '../storage/onboarding_prefill_storage.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/company/presentation/bloc/company_bloc.dart';
import '../../features/company/presentation/bloc/company_event.dart';
import '../../features/company/presentation/bloc/company_state.dart';
import '../../features/bookings/presentation/bloc/booking_bloc.dart';
import '../../features/workers/presentation/bloc/worker_bloc.dart';
import '../../features/work_types/presentation/bloc/work_type_bloc.dart';
import 'app_router_refresh_notifier.dart';
import 'custom_page_transitions.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter({
    required AppRouterRefreshNotifier refreshNotifier,
  }) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.login,
      refreshListenable: refreshNotifier,
      redirect: _redirect,
      routes: _routes,
    );
  }

  static String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final authState = context.read<AuthBloc>().state;
    final guardState = context.read<CompanyGuardCubit>().state;

    final isAuthRoute = location == AppRoutes.login ||
        location == AppRoutes.register ||
        location.startsWith('/forgot-password');

    if (authState is AuthInitial || authState is AuthLoading) {
      return null;
    }

    if (authState is AuthUnauthenticated) {
      if (isAuthRoute) return null;
      return AppRoutes.login;
    }

    if (authState is AuthAuthenticated) {
      if (guardState is CompanyGuardInitial ||
          guardState is CompanyGuardLoading) {
        return null;
      }

      if (guardState is CompanyGuardNoCompany) {
        if (guardState.skipped) {
          if (location == AppRoutes.login || location == AppRoutes.register) {
            return AppRoutes.dashboard;
          }
          return null;
        }
        if (location == AppRoutes.createCompany ||
            location == AppRoutes.onboardingSuccess) {
          return null;
        }
        return AppRoutes.createCompany;
      }

      if (guardState is CompanyGuardHasCompany) {
        if (location == AppRoutes.login ||
            location == AppRoutes.register ||
            location == AppRoutes.createCompany) {
          return AppRoutes.dashboard;
        }
        if (location == AppRoutes.addCompany ||
            location == AppRoutes.onboardingSuccess) {
          return null;
        }
        return null;
      }

      if (guardState is CompanyGuardError) {
        if (location == AppRoutes.createCompany ||
            location == AppRoutes.onboardingSuccess) {
          return null;
        }
        return AppRoutes.createCompany;
      }
    }

    return null;
  }

  static final List<RouteBase> _routes = [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kScaleFadePageTransitionDuration,
          reverseTransitionDuration: kScaleFadePageTransitionDuration,
          transitionsBuilder: scaleFadePageTransition,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kScaleFadePageTransitionDuration,
          reverseTransitionDuration: kScaleFadePageTransitionDuration,
          transitionsBuilder: scaleFadePageTransition,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kScaleFadePageTransitionDuration,
            reverseTransitionDuration: kScaleFadePageTransitionDuration,
            transitionsBuilder: scaleFadePageTransition,
            child: ForgotPasswordPage(initialEmail: email),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordVerify,
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kScaleFadePageTransitionDuration,
            reverseTransitionDuration: kScaleFadePageTransitionDuration,
            transitionsBuilder: scaleFadePageTransition,
            child: VerifyOtpPage(email: email),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordReset,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! ForgotPasswordResetExtra) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kScaleFadePageTransitionDuration,
              reverseTransitionDuration: kScaleFadePageTransitionDuration,
              transitionsBuilder: scaleFadePageTransition,
              child: const Scaffold(
                body: Center(child: Text('جلسة غير صالحة. يرجى البدء من جديد.')),
              ),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kScaleFadePageTransitionDuration,
            reverseTransitionDuration: kScaleFadePageTransitionDuration,
            transitionsBuilder: scaleFadePageTransition,
            child: ResetPasswordPage(
              email: extra.email,
              resetToken: extra.resetToken,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createCompany,
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          final user = authState.user;
          final cityId = OnboardingPrefillStorage.cityId ??
              int.tryParse(state.uri.queryParameters['cityId'] ?? '');
          OnboardingPrefillStorage.clear();
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider.value(value: context.read<CompanyGuardCubit>()),
                BlocProvider(create: (_) => getIt<CompanyBloc>()),
              ],
              child: CreateCompanyScreen(
                userId: user.id,
                initialPhone: user.phone,
                initialEmail: user.email,
                initialCityId: cityId,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.companies,
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider(create: (_) => getIt<CompanyBloc>()),
              ],
              child: const CompaniesManagementScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/companies/edit/:companyId',
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          final companyId = int.tryParse(state.pathParameters['companyId'] ?? '');
          final extra = state.extra;
          CompanyEntity? company;
          CompanyBloc? parentCompanyBloc;
          if (extra is EditCompanyRouteExtra) {
            company = extra.company;
            parentCompanyBloc = extra.companyBloc;
          } else if (extra is CompanyEntity) {
            company = extra;
          }
          if (authState is! AuthAuthenticated || companyId == null) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const Scaffold(
                body: Center(child: Text('بيانات الشركة غير متوفرة')),
              ),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider.value(value: context.read<CompanyGuardCubit>()),
                if (parentCompanyBloc != null)
                  BlocProvider.value(value: parentCompanyBloc)
                else
                  BlocProvider(create: (_) => getIt<CompanyBloc>()),
              ],
              child: EditCompanyEntryScreen(
                companyId: companyId,
                initialCompany: company,
                companyBloc: parentCompanyBloc,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addCompany,
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          final user = authState.user;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider.value(value: context.read<CompanyGuardCubit>()),
                BlocProvider(create: (_) => getIt<CompanyBloc>()),
              ],
              child: CreateCompanyScreen(
                userId: user.id,
                initialPhone: user.phone,
                initialEmail: user.email,
                mode: CompanyFormMode.add,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingSuccess,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! OnboardingSuccessExtra) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const Scaffold(
                body: Center(child: Text('جلسة غير صالحة')),
              ),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<CompanyGuardCubit>()),
                BlocProvider(create: (_) => getIt<CompanyBloc>()),
              ],
              child: _OnboardingSuccessRoute(extra: extra),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<AccountSettingsCubit>()),
            ],
            child: const ProfileScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<DeleteAccountCubit>()),
            ],
            child: const DeleteAccountScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        redirect: (_, __) => AppRoutes.profile,
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<CompanyBloc>()),
              BlocProvider(create: (_) => getIt<DashboardBloc>()),
            ],
            child: const DashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<CompanyBloc>()),
              BlocProvider(create: (_) => getIt<BookingBloc>()),
            ],
            child: const BookingsListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/bookings/detail/:bookingId',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final id = int.tryParse(state.pathParameters['bookingId'] ?? '');
          final parsed = extra is BookingDetailExtra ? extra : null;
          final valid = parsed != null && id != null && parsed.booking.id == id;
          if (!valid) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 320),
              reverseTransitionDuration: const Duration(milliseconds: 280),
              transitionsBuilder: slideFromRightPageTransition,
              child: const BookingDetailMissingScreen(),
            );
          }
          final e = parsed;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: slideFromRightPageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: e.bookingBloc),
                BlocProvider(
                  create: (_) => BookingDetailCubit(
                    getBookingByIdUseCase: getIt<GetBookingByIdUseCase>(),
                    initialBooking: e.booking,
                  ),
                ),
              ],
              child: const BookingDetailScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.workersAdd,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<CompanyBloc>()),
              BlocProvider(create: (_) => getIt<WorkerBloc>()),
            ],
            child: const AddWorkerScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: BlocProvider.value(
              value: context.read<NotificationsCubit>(),
              child: const NotificationsPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ratings,
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider(create: (_) => getIt<CompanyBloc>()),
                BlocProvider(create: (_) => getIt<CompanyRatingsCubit>()),
              ],
              child: const CompanyRatingsPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/workers/:workerId/reviews',
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          final workerId = int.tryParse(state.pathParameters['workerId'] ?? '');
          final extra = state.extra;
          final args = extra is WorkerReviewsPageArgs ? extra : null;
          if (workerId == null || args == null || args.workerId != workerId) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const Scaffold(
                body: Center(child: Text('بيانات العاملة غير متوفرة')),
              ),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: BlocProvider(
              create: (_) => getIt<WorkerReviewsCubit>(),
              child: WorkerReviewsPage(
                workerId: args.workerId,
                workerName: args.workerName,
                profileImage: args.profileImage,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/reviews/:reviewId',
        pageBuilder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const LoginScreen(),
            );
          }
          final reviewId = int.tryParse(state.pathParameters['reviewId'] ?? '');
          if (reviewId == null) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: kFadePageTransitionDuration,
              reverseTransitionDuration: kFadePageTransitionDuration,
              transitionsBuilder: fadePageTransition,
              child: const Scaffold(
                body: Center(child: Text('المراجعة غير موجودة')),
              ),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: ReviewDetailPage(reviewId: reviewId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.companyBookingReports,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: BlocProvider(
            create: (_) => getIt<CompanyBookingReportsCubit>(),
            child: const CompanyBookingReportsPage(),
          ),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) {
              final reportId =
                  int.tryParse(state.pathParameters['id'] ?? '');
              if (reportId == null) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  transitionDuration: kFadePageTransitionDuration,
                  reverseTransitionDuration: kFadePageTransitionDuration,
                  transitionsBuilder: fadePageTransition,
                  child: const Scaffold(
                    body: Center(child: Text('البلاغ غير موجود')),
                  ),
                );
              }
              return CustomTransitionPage<void>(
                key: state.pageKey,
                transitionDuration: kFadePageTransitionDuration,
                reverseTransitionDuration: kFadePageTransitionDuration,
                transitionsBuilder: fadePageTransition,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => getIt<BookingReportDetailCubit>(),
                    ),
                    BlocProvider(
                      create: (_) => getIt<UpdateBookingReportStatusCubit>(),
                    ),
                  ],
                  child: BookingReportDetailPage(reportId: reportId),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/workers/:workerId',
        pageBuilder: (context, state) {
          WorkerEntity? worker;
          var focusHealthCertificate = false;
          final extra = state.extra;
          if (extra is WorkerDetailExtra) {
            worker = extra.worker;
            focusHealthCertificate = extra.focusHealthCertificate;
          } else if (extra is WorkerEntity) {
            worker = extra;
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: kFadePageTransitionDuration,
            reverseTransitionDuration: kFadePageTransitionDuration,
            transitionsBuilder: fadePageTransition,
            child: worker == null
                ? const WorkerDetailMissingScreen()
                : WorkerDetailScreen(
                    worker: worker,
                    focusHealthCertificate: focusHealthCertificate,
                  ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.workers,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<CompanyBloc>()),
              BlocProvider(create: (_) => getIt<WorkerBloc>()),
            ],
            child: const WorkersListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.workTypesAdd,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<CompanyBloc>()),
              BlocProvider(create: (_) => getIt<WorkTypeBloc>()),
            ],
            child: const AddWorkTypeScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.workTypes,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: kFadePageTransitionDuration,
          reverseTransitionDuration: kFadePageTransitionDuration,
          transitionsBuilder: fadePageTransition,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<AuthBloc>()),
              BlocProvider(create: (_) => getIt<CompanyBloc>()),
              BlocProvider(create: (_) => getIt<WorkTypeBloc>()),
            ],
            child: const WorkTypesListScreen(),
          ),
        ),
      ),
    ];
}

class _OnboardingSuccessRoute extends StatefulWidget {
  const _OnboardingSuccessRoute({required this.extra});

  final OnboardingSuccessExtra extra;

  @override
  State<_OnboardingSuccessRoute> createState() => _OnboardingSuccessRouteState();
}

class _OnboardingSuccessRouteState extends State<_OnboardingSuccessRoute> {
  late OnboardingSuccessExtra _extra;

  @override
  void initState() {
    super.initState();
    _extra = widget.extra;
  }

  void _retryUpload() {
    final file = _extra.registerFile;
    if (file == null) return;
    context.read<CompanyBloc>().add(
          UploadCommercialRegisterEvent(
            companyId: _extra.company.id,
            fileName: file.name,
            filePath: file.path,
            bytes: file.bytes,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, state) {
        if (state is CommercialRegisterUploaded) {
          setState(() {
            _extra = OnboardingSuccessExtra(
              company: state.company,
              uploadFailed: false,
              fromAddCompany: _extra.fromAddCompany,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع السجل التجاري بنجاح')),
          );
        } else if (state is CompanyError && _extra.uploadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: OnboardingSuccessScreen(
        company: _extra.company,
        uploadFailed: _extra.uploadFailed,
        onRetryUpload: _extra.registerFile != null ? _retryUpload : null,
        fromAddCompany: _extra.fromAddCompany,
      ),
    );
  }
}

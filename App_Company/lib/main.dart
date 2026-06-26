import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_router_refresh_notifier.dart';
import 'core/constants/app_routes.dart';
import 'core/di/injection.dart';
import 'core/network/api_client.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/company/presentation/cubit/company_guard_cubit.dart';
import 'features/notifications/presentation/state/notifications_cubit.dart';
import 'features/bookings/presentation/cubit/booking_realtime_cubit.dart';
import 'core/widgets/realtime_notification_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencyInjection();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final CompanyGuardCubit _companyGuardCubit;
  late final NotificationsCubit _notificationsCubit;
  late final BookingRealtimeCubit _bookingRealtimeCubit;
  late final AppRouterRefreshNotifier _refreshNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const CheckAuthEvent());
    _companyGuardCubit = getIt<CompanyGuardCubit>();
    _notificationsCubit = getIt<NotificationsCubit>();
    _bookingRealtimeCubit = getIt<BookingRealtimeCubit>();
    _refreshNotifier = AppRouterRefreshNotifier(
      authBloc: _authBloc,
      companyGuardCubit: _companyGuardCubit,
      notificationsCubit: _notificationsCubit,
    );
    _router = AppRouter.createRouter(refreshNotifier: _refreshNotifier);
    getIt<ApiClient>().onUnauthorized = _handleUnauthorized;
  }

  void _handleUnauthorized() {
    _authBloc.add(const LogoutEvent());
    AppRouter.rootNavigatorKey.currentContext?.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    _authBloc.close();
    _companyGuardCubit.close();
    _notificationsCubit.close();
    _bookingRealtimeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _companyGuardCubit),
        BlocProvider.value(value: _notificationsCubit),
        BlocProvider.value(value: _bookingRealtimeCubit),
      ],
      child: RealtimeNotificationListener(
        child: MaterialApp.router(
          title: 'Bareq - companies',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: _router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ar', 'SA'),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
        ),
      ),
    );
  }
}

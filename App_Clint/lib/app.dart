import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/routing/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/di/injection_container.dart';
import 'core/constants/app_strings.dart';
import 'core/services/app_icon_badge_service.dart';
import 'features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'features/notifications/presentation/state/notifications_cubit.dart';
import 'features/notifications/presentation/state/notifications_state.dart';
import 'features/notifications/presentation/utils/notifications_badge_count.dart';

/// Main app widget
/// Configures MaterialApp with routing, themes, and localization
class BareqApp extends StatefulWidget {
  const BareqApp({super.key});

  @override
  State<BareqApp> createState() => _BareqAppState();
}

class _BareqAppState extends State<BareqApp> {
  final LanguageProvider _languageProvider = LanguageProvider.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _languageProvider,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Bareq',
          debugShowCheckedModeBanner: false,
          theme: LightTheme.theme,
          darkTheme: DarkTheme.theme,
          themeMode: ThemeMode.light,
          routerConfig: AppRouter.router,
          locale: _languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final theme = Theme.of(context);
            return MultiBlocListener(
              listeners: [
                BlocListener<NotificationsCubit, NotificationsState>(
                  bloc: sl<NotificationsCubit>(),
                  listenWhen: (previous, current) {
                    final prev = previous.launcherBadgeUnreadCount;
                    final next = current.launcherBadgeUnreadCount;
                    if (prev == null && next == null) return false;
                    return prev != next;
                  },
                  listener: (_, state) {
                    final count = state.launcherBadgeUnreadCount ?? 0;
                    final enabled = sl<NotificationPreferencesRepository>()
                        .current
                        .notificationsEnabled;
                    sl<AppIconBadgeService>().updateUnreadCount(
                      enabled ? count : 0,
                    );
                  },
                ),
                BlocListener<NotificationsCubit, NotificationsState>(
                  bloc: sl<NotificationsCubit>(),
                  listenWhen: (previous, current) =>
                      current is NotificationsLoaded &&
                      current.latestRealtime != null &&
                      current.latestRealtime!.notification.isAllowedBy(
                        sl<NotificationPreferencesRepository>().current,
                      ),
                  listener: (context, state) {
                if (state is! NotificationsLoaded ||
                    state.latestRealtime == null) {
                  return;
                }
                final locale = _languageProvider.locale;
                final notification = state.latestRealtime!.notification;
                if (!notification.isAllowedBy(
                  sl<NotificationPreferencesRepository>().current,
                )) {
                  sl<NotificationsCubit>().clearLatestRealtimeBanner();
                  return;
                }
                final title = notification.localizedTitle(locale);
                final message = notification.localizedMessage(locale);
                final messenger = ScaffoldMessenger.of(context);

                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (message.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(message),
                        ],
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    action: notification.isBookingNotification &&
                            notification.relatedEntityId != null
                        ? SnackBarAction(
                            label: locale.languageCode == 'ar'
                                ? 'عرض'
                                : 'View',
                            onPressed: () {
                              context.push(
                                AppStrings.bookingDetailsRoute(
                                  notification.relatedEntityId!.toString(),
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                );
                sl<NotificationsCubit>().clearLatestRealtimeBanner();
                  },
                ),
              ],
              child: Directionality(
                textDirection:
                    _languageProvider.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                child: DefaultTextStyle(
                  style: GoogleFonts.almarai(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

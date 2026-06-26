import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/services/app_icon_badge_service.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../state/notifications_cubit.dart';
import '../utils/notifications_badge_count.dart';
import '../state/notification_preferences_cubit.dart';
import '../state/notification_preferences_state.dart';

/// Single toggle to enable or disable all in-app notification alerts.
class NotificationMasterSwitchCard extends StatelessWidget {
  const NotificationMasterSwitchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final cubit = sl<NotificationPreferencesCubit>();

    return BlocBuilder<NotificationPreferencesCubit, NotificationPreferencesState>(
      bloc: cubit,
      builder: (context, state) {
        final enabled = switch (state) {
          NotificationPreferencesLoaded(:final preferences) =>
            preferences.notificationsEnabled,
          _ => true,
        };

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: SwitchListTile(
            title: Text(
              l10n?.translate('notificationsEnabled') ?? 'Notifications',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(
              l10n?.translate('notificationsEnabledHint') ??
                  'Show booking updates and other in-app alerts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
            value: enabled,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : null,
            ),
            onChanged: (value) async {
              await cubit.setNotificationsEnabled(value);
              if (!value) {
                await sl<AppIconBadgeService>().clear();
                return;
              }
              await sl<NotificationsCubit>().refreshUnreadBadge();
              final count =
                  sl<NotificationsCubit>().state.launcherBadgeUnreadCount ?? 0;
              if (sl<NotificationPreferencesRepository>()
                  .current
                  .notificationsEnabled) {
                await sl<AppIconBadgeService>().updateUnreadCount(count);
              }
            },
          ),
        );
      },
    );
  }
}

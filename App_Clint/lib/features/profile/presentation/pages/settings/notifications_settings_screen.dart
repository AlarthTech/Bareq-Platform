import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/localization/l10n_helper.dart';
import '../../../../../core/widgets/common/app_top_bar.dart';
import '../../../../notifications/presentation/state/notification_preferences_cubit.dart';
import '../../../../notifications/presentation/widgets/notification_master_switch_card.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = sl<NotificationPreferencesCubit>();
    cubit.load();
    cubit.startWatching();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('notifications') ?? 'Notifications',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n?.translate('notificationSettingsSubtitle') ??
                'Turn off to stop all in-app notification alerts. Booking updates still appear in the Bookings tab.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 20),
          const NotificationMasterSwitchCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n?.translate('notificationSettingsNote') ??
                        'This applies to alerts inside the app. Push notifications will be added in a future update.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

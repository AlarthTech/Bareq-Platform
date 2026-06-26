import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../state/notification_preferences_cubit.dart';
import '../state/notification_preferences_state.dart';
import '../widgets/notification_master_switch_card.dart';
import '../../../../core/widgets/common/app_empty_state.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../domain/entities/notification_entity.dart';
import '../state/notifications_cubit.dart';
import '../state/notifications_state.dart';
import '../utils/notification_date_grouping.dart';
import '../widgets/notification_date_section.dart';
import '../widgets/notification_list_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  late final NotificationsCubit _cubit;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = sl<NotificationsCubit>();
    _cubit.refreshFromServer();
    _scrollController.addListener(_onScroll);

    final preferencesCubit = sl<NotificationPreferencesCubit>();
    preferencesCubit.load();
    preferencesCubit.startWatching();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _cubit.refreshFromServer();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 200) {
      _cubit.loadNextPage();
    }
  }

  Future<void> _onNotificationTap(NotificationEntity notification) async {
    if (!notification.isRead) {
      await _cubit.markAsRead(notification.id);
    }

    if (!mounted) return;

    if (notification.isBookingReportStatusUpdated) {
      context.push(
        AppStrings.bookingReportDetailRoute(notification.relatedEntityId!),
      );
      return;
    }

    if (notification.isBookingNotification &&
        notification.relatedEntityId != null) {
      context.push(
        AppStrings.bookingDetailsRoute(
          notification.relatedEntityId!.toString(),
        ),
      );
    }
  }

  Widget _refreshableBody({
    required Widget child,
    required bool enableRefresh,
  }) {
    if (!enableRefresh) return child;

    return RefreshIndicator(
      onRefresh: _cubit.refreshFromServer,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppTopBar(
          title: l10n?.translate('notifications') ?? 'Notifications',
          showBackButton: true,
          onBackPressed: () => context.pop(),
          showNotificationBell: false,
        ),
        body: BlocBuilder<NotificationPreferencesCubit,
            NotificationPreferencesState>(
          bloc: sl<NotificationPreferencesCubit>(),
          builder: (context, prefState) {
            final notificationsEnabled = switch (prefState) {
              NotificationPreferencesLoaded(:final preferences) =>
                preferences.notificationsEnabled,
              _ => true,
            };

            return BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
            if (!notificationsEnabled) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: NotificationMasterSwitchCard(),
                  ),
                  Expanded(
                    child: _refreshableBody(
                      enableRefresh: true,
                      child: AppEmptyState(
                        icon: Icons.notifications_off_outlined,
                        title:
                            l10n?.translate('notificationsDisabledTitle') ??
                            'Notifications are turned off',
                        subtitle:
                            l10n?.translate('notificationsDisabledHint') ??
                            'Turn notifications on to see alerts here',
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is NotificationsListError) {
              return _refreshableBody(
                enableRefresh: true,
                child: AppEmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: state.message,
                  actionLabel: l10n?.translate('retry') ?? 'Retry',
                  onAction: _cubit.refreshFromServer,
                ),
              );
            }

            if (state is! NotificationsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.isLoadingList && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.items.isEmpty) {
              return _refreshableBody(
                enableRefresh: true,
                child: AppEmptyState(
                  icon: Icons.notifications_none_outlined,
                  title:
                      l10n?.translate('noNotificationsYet') ??
                      'لا توجد إشعارات',
                  subtitle:
                      l10n?.translate('notificationsEmptyHint') ??
                      'ستظهر تحديثات الحجز هنا',
                ),
              );
            }

            final grouped = groupNotificationsByDate<NotificationEntity>(
              state.items,
              (n) => n.createdAt,
            );

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: NotificationMasterSwitchCard(),
                ),
                if (state.unreadCount > 0)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _cubit.markAllAsRead,
                      child: Text(
                        l10n?.translate('markAllAsRead') ??
                            'تعليم الكل كمقروء',
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cubit.refreshFromServer,
                    color: AppColors.primary,
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final group in NotificationDateGroup.values)
                          NotificationDateSection(
                            title: notificationDateGroupLabel(
                              group,
                              (key) => l10n?.translate(key) ?? key,
                            ),
                            children: [
                              for (final notification in grouped[group]!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Dismissible(
                                    key: ValueKey(notification.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment:
                                          AlignmentDirectional.centerEnd,
                                      padding:
                                          const EdgeInsetsDirectional.only(
                                        end: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    onDismissed: (_) =>
                                        _cubit.deleteNotification(
                                      notification.id,
                                    ),
                                    child: NotificationListItem(
                                      notification: notification,
                                      onTap: () =>
                                          _onNotificationTap(notification),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (state.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
              },
            );
          },
        ),
      ),
    );
  }
}

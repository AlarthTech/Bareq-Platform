import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../domain/entities/notification_entity.dart';
import '../state/notifications_cubit.dart';
import '../state/notifications_state.dart';
import '../utils/notification_date_grouper.dart';
import '../utils/notification_navigation.dart';
import '../widgets/notification_list_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cubit = context.read<NotificationsCubit>();
    if (cubit.state is! NotificationsStateData) {
      cubit.loadFirstPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll - 200) {
      context.read<NotificationsCubit>().loadNextPage();
    }
  }

  Future<void> _onRefresh() {
    return context.read<NotificationsCubit>().refresh();
  }

  Future<void> _onNotificationTap(NotificationEntity notification) async {
    if (!notification.isRead) {
      await context.read<NotificationsCubit>().markAsRead(notification.id);
    }
    if (!mounted) return;
    await NotificationNavigationHelper.openNotificationTarget(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'الإشعارات',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is! NotificationsStateData || state.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
                child: const Text('تحديد الكل كمقروء'),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listenWhen: (prev, curr) =>
            curr is NotificationsStateData && curr.errorMessage != null,
        listener: (context, state) {
          if (state is NotificationsStateData && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationsInitial ||
              (state is NotificationsStateData &&
                  state.isRefreshing &&
                  state.notifications.isEmpty)) {
            return _buildLoading();
          }

          if (state is! NotificationsStateData) {
            return const Center(child: Text('لا توجد إشعارات'));
          }

          if (state.isEmpty && !state.isRefreshing) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryTeal,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Icon(Icons.notifications_none_outlined,
                        size: 64, color: AppTheme.gray400),
                  ),
                  SizedBox(height: 16),
                  Center(child: Text('لا توجد إشعارات حالياً')),
                ],
              ),
            );
          }

          final sections = _buildSections(state.notifications);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryTeal,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sections.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= sections.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppTheme.spacing16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final section = sections[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacing16,
                        AppTheme.spacing16,
                        AppTheme.spacing16,
                        AppTheme.spacing8,
                      ),
                      child: Text(
                        NotificationDateGrouper.sectionLabel(section.key),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.gray700,
                            ),
                      ),
                    ),
                    ...section.value.map(
                      (notification) => NotificationListItem(
                        notification: notification,
                        isArabic: isArabic,
                        onTap: () => _onNotificationTap(notification),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: List.generate(
        6,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmerWidget(
            height: 72,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  List<MapEntry<NotificationDateSection, List<NotificationEntity>>> _buildSections(
    List<NotificationEntity> notifications,
  ) {
    final grouped = <NotificationDateSection, List<NotificationEntity>>{};

    for (final notification in notifications) {
      final section = NotificationDateGrouper.sectionFor(notification.createdAt);
      grouped.putIfAbsent(section, () => []).add(notification);
    }

    const order = [
      NotificationDateSection.today,
      NotificationDateSection.yesterday,
      NotificationDateSection.earlier,
    ];

    return order
        .where((s) => grouped.containsKey(s))
        .map((s) => MapEntry(s, grouped[s]!))
        .toList();
  }
}

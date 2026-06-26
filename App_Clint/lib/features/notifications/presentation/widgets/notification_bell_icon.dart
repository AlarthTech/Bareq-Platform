import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../state/notification_preferences_cubit.dart';
import '../state/notification_preferences_state.dart';
import '../state/notifications_cubit.dart';
import '../state/notifications_state.dart';

class NotificationBellIcon extends StatefulWidget {
  const NotificationBellIcon({super.key});

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _unreadCount(NotificationsState state) => switch (state) {
        NotificationsLoaded(:final unreadCount) => unreadCount,
        NotificationsListError(:final unreadCount) => unreadCount,
        _ => 0,
      };

  int _displayUnreadCount(NotificationsState state) {
    if (!sl<NotificationPreferencesRepository>().current.notificationsEnabled) {
      return 0;
    }
    return _unreadCount(state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      bloc: sl<NotificationsCubit>(),
      listenWhen: (previous, current) {
        final next = _displayUnreadCount(current);
        final prev = _displayUnreadCount(previous);
        return next > prev;
      },
      listener: (context, state) {
        _pulseController.forward(from: 0).then((_) {
          if (mounted) _pulseController.reverse();
        });
      },
      builder: (context, state) {
        return BlocBuilder<NotificationPreferencesCubit,
            NotificationPreferencesState>(
          bloc: sl<NotificationPreferencesCubit>(),
          builder: (context, _) {
            final unreadCount = _displayUnreadCount(state);

            return IconButton(
          onPressed: () => context.push(AppStrings.routeNotifications),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 26,
              ),
              if (unreadCount > 0)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
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
  int _lastPulseToken = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _maybePulse(int token) {
    if (token > _lastPulseToken) {
      _lastPulseToken = token;
      _pulseController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount =
            state is NotificationsStateData ? state.unreadCount : 0;
        final pulseToken =
            state is NotificationsStateData ? state.badgePulseToken : 0;
        _maybePulse(pulseToken);

        return IconButton(
          tooltip: 'الإشعارات',
          onPressed: () => context.push(AppRoutes.notifications),
          icon: ScaleTransition(
            scale: _pulseAnimation,
            child: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: AppTheme.dangerRed,
              child: const Icon(Icons.notifications_outlined, size: 24),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../features/notifications/domain/usecases/subscribe_to_notifications.dart';

/// Shows in-app snackbars when SignalR delivers realtime notifications.
class RealtimeNotificationListener extends StatefulWidget {
  const RealtimeNotificationListener({super.key, required this.child});

  final Widget child;

  @override
  State<RealtimeNotificationListener> createState() =>
      _RealtimeNotificationListenerState();
}

class _RealtimeNotificationListenerState
    extends State<RealtimeNotificationListener> {
  StreamSubscription<String>? _toastSub;

  @override
  void initState() {
    super.initState();
    _toastSub = getIt<SubscribeToNotificationsUseCase>()
        .watchToastMessages()
        .listen(_showToast);
  }

  void _showToast(String message) {
    if (message.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryTeal,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: messenger.hideCurrentSnackBar,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _toastSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

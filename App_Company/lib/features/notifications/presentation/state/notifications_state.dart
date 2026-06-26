import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_entity.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsStateData extends NotificationsState {
  const NotificationsStateData({
    required this.unreadCount,
    required this.notifications,
    required this.currentPage,
    required this.hasNextPage,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isConnectingRealtime = false,
    this.errorMessage,
    this.badgePulseToken = 0,
  });

  final int unreadCount;
  final List<NotificationEntity> notifications;
  final int currentPage;
  final bool hasNextPage;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isConnectingRealtime;
  final String? errorMessage;
  /// Increments on each realtime notification to drive badge animation.
  final int badgePulseToken;

  bool get isEmpty => notifications.isEmpty;

  NotificationsStateData copyWith({
    int? unreadCount,
    List<NotificationEntity>? notifications,
    int? currentPage,
    bool? hasNextPage,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isConnectingRealtime,
    String? errorMessage,
    int? badgePulseToken,
    bool clearError = false,
  }) {
    return NotificationsStateData(
      unreadCount: unreadCount ?? this.unreadCount,
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isConnectingRealtime: isConnectingRealtime ?? this.isConnectingRealtime,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      badgePulseToken: badgePulseToken ?? this.badgePulseToken,
    );
  }

  @override
  List<Object?> get props => [
        unreadCount,
        notifications,
        currentPage,
        hasNextPage,
        isRefreshing,
        isLoadingMore,
        isConnectingRealtime,
        errorMessage,
        badgePulseToken,
      ];
}

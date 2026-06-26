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

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required this.unreadCount,
    this.items = const [],
    this.isLoadingList = false,
    this.isLoadingMore = false,
    this.hasNextPage = false,
    this.page = 1,
    this.totalCount = 0,
    this.listError,
    this.latestRealtime,
  });

  final int unreadCount;
  final List<NotificationEntity> items;
  final bool isLoadingList;
  final bool isLoadingMore;
  final bool hasNextPage;
  final int page;
  final int totalCount;
  final String? listError;
  final NotificationRealtimeUpdate? latestRealtime;

  bool get hasListData => items.isNotEmpty || listError != null;

  NotificationsLoaded copyWith({
    int? unreadCount,
    List<NotificationEntity>? items,
    bool? isLoadingList,
    bool? isLoadingMore,
    bool? hasNextPage,
    int? page,
    int? totalCount,
    String? listError,
    bool clearListError = false,
    NotificationRealtimeUpdate? latestRealtime,
    bool clearLatestRealtime = false,
  }) {
    return NotificationsLoaded(
      unreadCount: unreadCount ?? this.unreadCount,
      items: items ?? this.items,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      listError: clearListError ? null : (listError ?? this.listError),
      latestRealtime: clearLatestRealtime
          ? null
          : (latestRealtime ?? this.latestRealtime),
    );
  }

  @override
  List<Object?> get props => [
        unreadCount,
        items,
        isLoadingList,
        isLoadingMore,
        hasNextPage,
        page,
        totalCount,
        listError,
        latestRealtime,
      ];
}

class NotificationsListError extends NotificationsState {
  const NotificationsListError({
    required this.message,
    this.unreadCount = 0,
  });

  final String message;
  final int unreadCount;

  @override
  List<Object?> get props => [message, unreadCount];
}

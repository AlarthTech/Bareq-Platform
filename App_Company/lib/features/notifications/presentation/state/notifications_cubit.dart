import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/notification_local_storage.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../../bookings/presentation/cubit/booking_realtime_cubit.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/realtime_hub_event.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_count.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../domain/usecases/subscribe_to_notifications.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
    required SubscribeToNotificationsUseCase subscribeToNotificationsUseCase,
    required BookingRealtimeCubit bookingRealtimeCubit,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
        _subscribeToNotificationsUseCase = subscribeToNotificationsUseCase,
        _bookingRealtimeCubit = bookingRealtimeCubit,
        super(const NotificationsInitial());

  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;
  final SubscribeToNotificationsUseCase _subscribeToNotificationsUseCase;
  final BookingRealtimeCubit _bookingRealtimeCubit;

  StreamSubscription<RealtimeHubEvent>? _realtimeSub;
  static const _pageSize = 20;

  NotificationsStateData? get _data =>
      state is NotificationsStateData ? state as NotificationsStateData : null;

  Future<void> connectAndSync() async {
    final token = await SecureTokenStorage.readToken();
    if (token == null || token.isEmpty) return;

    final cachedNotifications = await NotificationLocalStorage.readNotifications();
    final cachedUnread = await NotificationLocalStorage.readUnreadCount();

    emit(
      NotificationsStateData(
        unreadCount: cachedUnread,
        notifications: cachedNotifications,
        currentPage: cachedNotifications.isEmpty ? 0 : 1,
        hasNextPage: false,
        isConnectingRealtime: true,
      ),
    );

    await _realtimeSub?.cancel();
    try {
      await _subscribeToNotificationsUseCase.connect(token);
      _realtimeSub = _subscribeToNotificationsUseCase.watchHubEvents().listen(
        _onHubEvent,
        onError: (_) {},
      );
    } catch (_) {
      // Realtime is best-effort; REST still works.
    }

    await refreshUnreadCount();
    if (_data == null || _data!.notifications.isEmpty) {
      await loadFirstPage();
    } else {
      emit(_data!.copyWith(isConnectingRealtime: false, clearError: true));
    }
  }

  Future<void> disconnect() async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    await _subscribeToNotificationsUseCase.disconnect();
    await NotificationLocalStorage.clear();
    emit(const NotificationsInitial());
  }

  void _onHubEvent(RealtimeHubEvent event) {
    switch (event) {
      case RealtimeNotificationReceived(:final update):
        onRealtimeNotificationReceived(update);
      case RealtimeBookingStatusChanged(:final bookingEvent):
        _bookingRealtimeCubit.onBookingStatusChanged(bookingEvent);
        if (event.notificationUpdate != null) {
          onRealtimeNotificationReceived(event.notificationUpdate!);
        }
      case RealtimeToastMessage():
        break;
    }
  }

  /// Equivalent to [RealtimeNotificationReceived] bloc event.
  void onRealtimeNotificationReceived(NotificationRealtimeUpdate update) {
    final current = _data;
    final notification = update.notification;

    final existingIndex = current?.notifications
            .indexWhere((n) => n.id == notification.id) ??
        -1;
    final updatedList = current != null
        ? List<NotificationEntity>.from(current.notifications)
        : <NotificationEntity>[];

    if (existingIndex >= 0) {
      updatedList[existingIndex] = notification;
    } else {
      updatedList.insert(0, notification);
    }

    final nextUnread = update.unreadCount >= 0
        ? update.unreadCount
        : (current?.unreadCount ?? 0) + (notification.isRead ? 0 : 1);

    final nextState = NotificationsStateData(
      unreadCount: nextUnread,
      notifications: updatedList,
      currentPage: current?.currentPage ?? 1,
      hasNextPage: current?.hasNextPage ?? false,
      isConnectingRealtime: false,
      badgePulseToken: (current?.badgePulseToken ?? 0) + 1,
    );

    emit(nextState);
    unawaited(_persist(nextState));
  }

  Future<void> _persist(NotificationsStateData data) async {
    await NotificationLocalStorage.saveNotifications(data.notifications);
    await NotificationLocalStorage.saveUnreadCount(data.unreadCount);
  }

  Future<void> refreshUnreadCount() async {
    final result = await _getUnreadCountUseCase();
    result.fold(
      (_) {},
      (count) {
        final current = _data;
        if (current != null) {
          final next = current.copyWith(unreadCount: count, clearError: true);
          emit(next);
          unawaited(_persist(next));
        } else {
          emit(
            NotificationsStateData(
              unreadCount: count,
              notifications: const [],
              currentPage: 0,
              hasNextPage: false,
            ),
          );
        }
      },
    );
  }

  Future<void> loadFirstPage() async {
    final current = _data;
    emit(
      (current ??
              const NotificationsStateData(
                unreadCount: 0,
                notifications: [],
                currentPage: 0,
                hasNextPage: false,
              ))
          .copyWith(isRefreshing: true, clearError: true),
    );

    final notificationsResult = await _getNotificationsUseCase(
      const GetNotificationsParams(page: 1, pageSize: _pageSize),
    );
    final unreadResult = await _getUnreadCountUseCase();

    notificationsResult.fold(
      (failure) {
        emit(
          (_data ??
                  const NotificationsStateData(
                    unreadCount: 0,
                    notifications: [],
                    currentPage: 0,
                    hasNextPage: false,
                  ))
              .copyWith(
            isRefreshing: false,
            isConnectingRealtime: false,
            errorMessage: failure.message,
          ),
        );
      },
      (page) {
        final unread = unreadResult.fold((_) => _data?.unreadCount ?? 0, (c) => c);
        final next = NotificationsStateData(
          unreadCount: unread,
          notifications: page.items,
          currentPage: page.page,
          hasNextPage: page.hasNextPage,
          isRefreshing: false,
          isConnectingRealtime: false,
        );
        emit(next);
        unawaited(_persist(next));
      },
    );
  }

  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    final current = _data;
    if (current == null ||
        !current.hasNextPage ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true, clearError: true));

    final nextPage = current.currentPage + 1;
    final result = await _getNotificationsUseCase(
      GetNotificationsParams(page: nextPage, pageSize: _pageSize),
    );

    result.fold(
      (failure) => emit(
        current.copyWith(isLoadingMore: false, errorMessage: failure.message),
      ),
      (page) {
        final merged = [...current.notifications, ...page.items];
        final next = current.copyWith(
          notifications: merged,
          currentPage: page.page,
          hasNextPage: page.hasNextPage,
          isLoadingMore: false,
        );
        emit(next);
        unawaited(_persist(next));
      },
    );
  }

  Future<void> markAsRead(int notificationId) async {
    final current = _data;
    if (current == null) return;

    final result = await _markNotificationReadUseCase(notificationId);
    result.fold(
      (failure) => emit(current.copyWith(errorMessage: failure.message)),
      (_) {
        final updated = current.notifications
            .map(
              (n) => n.id == notificationId ? n.copyWith(isRead: true) : n,
            )
            .toList();
        final next = current.copyWith(
          notifications: updated,
          unreadCount: updated.where((n) => !n.isRead).length,
          clearError: true,
        );
        emit(next);
        unawaited(_persist(next));
        refreshUnreadCount();
      },
    );
  }

  Future<void> markAllAsRead() async {
    final current = _data;
    if (current == null) return;

    final result = await _markAllNotificationsReadUseCase();
    result.fold(
      (failure) => emit(current.copyWith(errorMessage: failure.message)),
      (_) {
        final updated =
            current.notifications.map((n) => n.copyWith(isRead: true)).toList();
        final next = current.copyWith(
          notifications: updated,
          unreadCount: 0,
          clearError: true,
        );
        emit(next);
        unawaited(_persist(next));
      },
    );
  }

  @override
  Future<void> close() async {
    await _realtimeSub?.cancel();
    return super.close();
  }
}

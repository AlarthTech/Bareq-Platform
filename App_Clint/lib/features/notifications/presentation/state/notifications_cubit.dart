import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
    required DeleteNotificationUseCase deleteNotificationUseCase,
    required WatchRealtimeNotificationsUseCase watchRealtimeNotificationsUseCase,
    required ConnectNotificationHubUseCase connectNotificationHubUseCase,
    required DisconnectNotificationHubUseCase disconnectNotificationHubUseCase,
    required NotificationPreferencesRepository notificationPreferencesRepository,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
        _deleteNotificationUseCase = deleteNotificationUseCase,
        _watchRealtimeNotificationsUseCase = watchRealtimeNotificationsUseCase,
        _connectNotificationHubUseCase = connectNotificationHubUseCase,
        _disconnectNotificationHubUseCase =
            disconnectNotificationHubUseCase,
        _notificationPreferencesRepository =
            notificationPreferencesRepository,
        super(const NotificationsInitial());

  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final WatchRealtimeNotificationsUseCase _watchRealtimeNotificationsUseCase;
  final ConnectNotificationHubUseCase _connectNotificationHubUseCase;
  final DisconnectNotificationHubUseCase _disconnectNotificationHubUseCase;
  final NotificationPreferencesRepository _notificationPreferencesRepository;

  StreamSubscription<NotificationRealtimeUpdate>? _realtimeSubscription;
  StreamSubscription<NotificationPreferences>? _preferencesSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _notificationPreferencesRepository.load();

    await _refreshUnreadCount();
    await _connectHub();

    await _realtimeSubscription?.cancel();
    _realtimeSubscription = _watchRealtimeNotificationsUseCase().listen(
      _onRealtimeNotification,
    );

    await _preferencesSubscription?.cancel();
    _preferencesSubscription =
        _notificationPreferencesRepository.watch().listen((_) {
      _refilterCurrentList();
    });
  }

  Future<void> reset() async {
    _initialized = false;
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    await _preferencesSubscription?.cancel();
    _preferencesSubscription = null;
    await _disconnectNotificationHubUseCase();
    emit(const NotificationsInitial());
  }

  Future<void> _connectHub() async {
    try {
      await _connectNotificationHubUseCase();
    } catch (_) {
      // Hub is best-effort; REST still works offline/next open.
    }
  }

  void _onRealtimeNotification(NotificationRealtimeUpdate update) {
    if (!_isNotificationAllowed(update.notification)) return;
    _applyRealtimeUpdate(update);
  }

  /// SignalR / realtime service entry point (Bloc-style event equivalent).
  void realtimeNotificationReceived(
    NotificationEntity notification, {
    int? unreadCount,
  }) {
    if (!_isNotificationAllowed(notification)) return;

    final current = state;
    final resolvedUnread = unreadCount ??
        switch (current) {
          NotificationsLoaded(:final unreadCount) => unreadCount + 1,
          NotificationsListError(:final unreadCount) => unreadCount + 1,
          _ => 1,
        };

    _applyRealtimeUpdate(
      NotificationRealtimeUpdate(
        notification: notification,
        unreadCount: resolvedUnread,
      ),
    );
  }

  void _applyRealtimeUpdate(NotificationRealtimeUpdate update) {
    final current = state;
    if (current is NotificationsLoaded) {
      final exists = current.items.any((n) => n.id == update.notification.id);
      final items =
          exists
              ? current.items
              : [update.notification, ...current.items];
      final unread =
          exists
              ? current.unreadCount
              : update.unreadCount;
      emit(
        current.copyWith(
          unreadCount: unread,
          items: items,
          latestRealtime: exists ? null : update,
          clearLatestRealtime: exists,
        ),
      );
      return;
    }

    emit(
      NotificationsLoaded(
        unreadCount: update.unreadCount,
        items: [update.notification],
        latestRealtime: update,
      ),
    );
  }

  Future<void> _refreshUnreadCount() async {
    final result = await _getUnreadCountUseCase();
    result.fold(
      (_) {},
      (count) {
        final current = state;
        if (current is NotificationsLoaded) {
          emit(current.copyWith(unreadCount: count));
        } else if (current is NotificationsListError) {
          emit(NotificationsListError(message: current.message, unreadCount: count));
        } else {
          emit(NotificationsLoaded(unreadCount: count));
        }
      },
    );
  }

  Future<void> loadFirstPage() async {
    if (isClosed) return;

    final current = state;
    if (current is NotificationsLoaded) {
      emit(current.copyWith(isLoadingList: true, clearListError: true));
    } else {
      emit(
        NotificationsLoaded(
          unreadCount: current is NotificationsListError
              ? current.unreadCount
              : 0,
          isLoadingList: true,
        ),
      );
    }

    await _loadPage(
      page: PaginationConstants.defaultPage,
      reset: true,
    );
  }

  Future<void> refreshList() => refreshFromServer();

  /// Fetches unread count + latest notifications from the API (pull-to-refresh).
  Future<void> refreshFromServer() async {
    if (isClosed) return;
    await _refreshUnreadCount();
    await loadFirstPage();
  }

  /// Updates the bell badge from the server without reloading the full list.
  Future<void> refreshUnreadBadge() => _refreshUnreadCount();

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! NotificationsLoaded ||
        !current.hasNextPage ||
        current.isLoadingMore ||
        current.isLoadingList) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    await _loadPage(page: current.page + 1, reset: false);
  }

  Future<void> _loadPage({required int page, required bool reset}) async {
    final result = await _getNotificationsUseCase(
      page: page,
      pageSize: PaginationConstants.defaultPageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        final unread =
            state is NotificationsLoaded
                ? (state as NotificationsLoaded).unreadCount
                : state is NotificationsListError
                    ? (state as NotificationsListError).unreadCount
                    : 0;
        if (reset && state is! NotificationsLoaded) {
          emit(
            NotificationsListError(
              message: _mapFailure(failure),
              unreadCount: unread,
            ),
          );
        } else if (state is NotificationsLoaded) {
          final current = state as NotificationsLoaded;
          emit(
            current.copyWith(
              isLoadingList: false,
              isLoadingMore: false,
              listError: _mapFailure(failure),
            ),
          );
        }
      },
      (paged) {
        final previous =
            (!reset && state is NotificationsLoaded)
                ? (state as NotificationsLoaded).items
                : <NotificationEntity>[];
        final merged = _filterByPreferences(
          reset ? paged.items : [...previous, ...paged.items],
        );
        final unread =
            state is NotificationsLoaded
                ? (state as NotificationsLoaded).unreadCount
                : state is NotificationsListError
                    ? (state as NotificationsListError).unreadCount
                    : 0;

        emit(
          NotificationsLoaded(
            unreadCount: unread,
            items: merged,
            isLoadingList: false,
            isLoadingMore: false,
            hasNextPage: paged.hasNextPage,
            page: paged.page,
            totalCount: paged.totalCount,
          ),
        );
      },
    );

    if (reset) {
      await _refreshUnreadCount();
    }
  }

  Future<void> markAsRead(int id) async {
    final result = await _markNotificationReadUseCase(id);
    if (isClosed) return;

    result.fold((_) {}, (_) {
      final current = state;
      if (current is! NotificationsLoaded) return;
      final items =
          current.items
              .map(
                (n) => n.id == id ? n.copyWith(isRead: true) : n,
              )
              .toList();
      final unread = current.unreadCount > 0 ? current.unreadCount - 1 : 0;
      emit(
        current.copyWith(
          items: items,
          unreadCount: unread,
        ),
      );
    });
  }

  Future<void> markAllAsRead() async {
    final result = await _markAllNotificationsReadUseCase();
    if (isClosed) return;

    result.fold((_) {}, (_) {
      final current = state;
      if (current is NotificationsLoaded) {
        emit(
          current.copyWith(
            unreadCount: 0,
            items:
                current.items
                    .map((n) => n.copyWith(isRead: true))
                    .toList(),
          ),
        );
      } else {
        emit(const NotificationsLoaded(unreadCount: 0));
      }
    });
  }

  Future<void> deleteNotification(int id) async {
    final result = await _deleteNotificationUseCase(id);
    if (isClosed) return;

    result.fold((_) {}, (_) {
      final current = state;
      if (current is! NotificationsLoaded) return;
      final removed = current.items.firstWhere((n) => n.id == id);
      final items = current.items.where((n) => n.id != id).toList();
      final unread =
          !removed.isRead && current.unreadCount > 0
              ? current.unreadCount - 1
              : current.unreadCount;
      emit(current.copyWith(items: items, unreadCount: unread));
    });
  }

  void clearLatestRealtimeBanner() {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(current.copyWith(clearLatestRealtime: true));
    }
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription?.cancel();
    return super.close();
  }

  NotificationPreferences get _preferences =>
      _notificationPreferencesRepository.current;

  bool _isNotificationAllowed(NotificationEntity notification) =>
      notification.isAllowedBy(_preferences);

  List<NotificationEntity> _filterByPreferences(
    List<NotificationEntity> items,
  ) =>
      items.where(_isNotificationAllowed).toList();

  void _refilterCurrentList() {
    final current = state;
    if (current is! NotificationsLoaded) return;
    emit(
      current.copyWith(
        items: _filterByPreferences(current.items),
        clearLatestRealtime: true,
      ),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is NetworkFailure) {
      return 'خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }
    return failure.message;
  }
}

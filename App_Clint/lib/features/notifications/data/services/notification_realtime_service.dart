import 'dart:async';

import '../../../booking/domain/entities/booking_status_changed_event.dart';
import '../../../booking/presentation/state/booking_realtime_cubit.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/usecases/notification_usecases.dart';
import '../../presentation/state/notifications_cubit.dart';

/// Singleton orchestrator for SignalR notification + booking status streams.
class NotificationRealtimeService {
  NotificationRealtimeService({
    required WatchBookingStatusChangesUseCase watchBookingStatusChangesUseCase,
    required NotificationsCubit notificationsCubit,
    required BookingRealtimeCubit bookingRealtimeCubit,
    required NotificationPreferencesRepository notificationPreferencesRepository,
  })  : _watchBookingStatusChangesUseCase =
            watchBookingStatusChangesUseCase,
        _notificationsCubit = notificationsCubit,
        _bookingRealtimeCubit = bookingRealtimeCubit,
        _notificationPreferencesRepository =
            notificationPreferencesRepository;

  final WatchBookingStatusChangesUseCase _watchBookingStatusChangesUseCase;
  final NotificationsCubit _notificationsCubit;
  final BookingRealtimeCubit _bookingRealtimeCubit;
  final NotificationPreferencesRepository _notificationPreferencesRepository;

  StreamSubscription<BookingStatusChangedEvent>? _bookingSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _bookingSubscription?.cancel();
    _bookingSubscription = _watchBookingStatusChangesUseCase().listen(
      _onBookingStatusChanged,
    );
  }

  Future<void> stop() async {
    _started = false;
    await _bookingSubscription?.cancel();
    _bookingSubscription = null;
    _bookingRealtimeCubit.reset();
  }

  void _onBookingStatusChanged(BookingStatusChangedEvent event) {
    _bookingRealtimeCubit.applyStatusChange(event);

    final notification = NotificationEntity(
      id: event.notificationId > 0 ? event.notificationId : event.bookingId,
      title: event.title,
      titleAr: event.title,
      message: event.message,
      messageAr: event.message,
      notificationType: 1,
      relatedEntityId: event.bookingId,
      isRead: false,
      createdAt: event.createdAt,
    );

    if (!notification.isAllowedBy(_notificationPreferencesRepository.current)) {
      return;
    }

    _notificationsCubit.realtimeNotificationReceived(notification);
  }
}

import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/notification_entity.dart';
import '../../../booking/domain/entities/booking_status_changed_event.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, PagedResult<NotificationEntity>>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getMyNotifications(page: page, pageSize: pageSize);
  }
}

class GetUnreadCountUseCase {
  GetUnreadCountUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, int>> call() => _repository.getUnreadCount();
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, void>> call(int id) =>
      _repository.markAsRead(id);
}

class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, void>> call() => _repository.markAllAsRead();
}

class DeleteNotificationUseCase {
  DeleteNotificationUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, void>> call(int id) =>
      _repository.deleteNotification(id);
}

class WatchRealtimeNotificationsUseCase {
  WatchRealtimeNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Stream<NotificationRealtimeUpdate> call() =>
      _repository.watchRealtimeNotifications();
}

class ConnectNotificationHubUseCase {
  ConnectNotificationHubUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call() => _repository.connectRealtime();
}

class DisconnectNotificationHubUseCase {
  DisconnectNotificationHubUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call() => _repository.disconnectRealtime();
}

class WatchBookingStatusChangesUseCase {
  WatchBookingStatusChangesUseCase(this._repository);

  final NotificationRepository _repository;

  Stream<BookingStatusChangedEvent> call() =>
      _repository.watchBookingStatusChanges();
}

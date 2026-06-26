import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../booking/domain/entities/booking_status_changed_event.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, PagedResult<NotificationEntity>>> getMyNotifications({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> markAsRead(int id);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, void>> deleteNotification(int id);

  Stream<NotificationRealtimeUpdate> watchRealtimeNotifications();

  Stream<BookingStatusChangedEvent> watchBookingStatusChanges();

  Future<void> connectRealtime();

  Future<void> disconnectRealtime();
}

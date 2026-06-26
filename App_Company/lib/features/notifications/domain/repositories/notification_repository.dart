import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../entities/realtime_hub_event.dart';
import 'package:dartz/dartz.dart';

abstract class NotificationRepository {
  Future<Either<Failure, PagedResult<NotificationEntity>>> getNotifications({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> markAsRead(int notificationId);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, void>> deleteNotification(int notificationId);

  Stream<NotificationRealtimeUpdate> watchRealtimeUpdates();

  Stream<RealtimeHubEvent> watchHubEvents();

  Future<void> connectRealtime(String accessToken);

  Future<void> disconnectRealtime();
}

import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/realtime_hub_event.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../services/notification_realtime_service.dart';
import 'package:dartz/dartz.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
    required NotificationRealtimeService realtimeService,
  })  : _remoteDataSource = remoteDataSource,
        _realtimeService = realtimeService;

  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationRealtimeService _realtimeService;

  @override
  Future<Either<Failure, PagedResult<NotificationEntity>>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final pageResult = await _remoteDataSource.getNotifications(
        page: page,
        pageSize: pageSize,
      );
      return Right(
        PagedResult<NotificationEntity>(
          items: pageResult.items.map((m) => m.toEntity()).toList(),
          page: pageResult.page,
          pageSize: pageResult.pageSize,
          totalCount: pageResult.totalCount,
          totalPages: pageResult.totalPages,
          hasNextPage: pageResult.hasNextPage,
          hasPreviousPage: pageResult.hasPreviousPage,
        ),
      );
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await _remoteDataSource.getUnreadCount();
      return Right(count);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int notificationId) async {
    try {
      await _remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _remoteDataSource.markAllAsRead();
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int notificationId) async {
    try {
      await _remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Stream<NotificationRealtimeUpdate> watchRealtimeUpdates() {
    return _realtimeService.notificationUpdates;
  }

  @override
  Stream<RealtimeHubEvent> watchHubEvents() {
    return _realtimeService.events;
  }

  @override
  Future<void> connectRealtime(String accessToken) {
    return _realtimeService.connect(accessToken);
  }

  @override
  Future<void> disconnectRealtime() {
    return _realtimeService.disconnect();
  }
}

import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../booking/domain/entities/booking_status_changed_event.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../datasources/notification_signalr_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
    required NotificationSignalRDataSource signalRDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _signalRDataSource = signalRDataSource;

  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationSignalRDataSource _signalRDataSource;

  @override
  Future<Either<Failure, PagedResult<NotificationEntity>>> getMyNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final paged = await _remoteDataSource.getMyNotifications(
        page: page,
        pageSize: pageSize,
      );
      return Right(_mapPaged(paged));
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await _remoteDataSource.getUnreadCount();
      return Right(count);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      await _remoteDataSource.markAsRead(id);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await _remoteDataSource.markAllAsRead();
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int id) async {
    try {
      await _remoteDataSource.deleteNotification(id);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Stream<NotificationRealtimeUpdate> watchRealtimeNotifications() {
    return _signalRDataSource.watchNotifications();
  }

  @override
  Stream<BookingStatusChangedEvent> watchBookingStatusChanges() {
    return _signalRDataSource.watchBookingStatusChanges();
  }

  @override
  Future<void> connectRealtime() => _signalRDataSource.connect();

  @override
  Future<void> disconnectRealtime() => _signalRDataSource.disconnect();

  PagedResult<NotificationEntity> _mapPaged(
    PagedResult<NotificationModel> paged,
  ) {
    return PagedResult<NotificationEntity>(
      items: paged.items.map((m) => m.toEntity()).toList(),
      page: paged.page,
      pageSize: paged.pageSize,
      totalCount: paged.totalCount,
      totalPages: paged.totalPages,
      hasNextPage: paged.hasNextPage,
      hasPreviousPage: paged.hasPreviousPage,
    );
  }
}

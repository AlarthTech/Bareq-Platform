import 'package:dio/dio.dart';

import '../../../../core/data/models/paged_result.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<PagedResult<NotificationModel>> getMyNotifications({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  });

  Future<int> getUnreadCount();

  Future<void> markAsRead(int id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(int id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<PagedResult<NotificationModel>> getMyNotifications({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.getMyNotifications,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(response.data, NotificationModel.fromJson);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.getUnreadCount);
      final model = UnreadCountModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return model.count;
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      await _dioClient.patch(ApiEndpoints.markNotificationAsRead(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dioClient.patch(ApiEndpoints.markAllNotificationsAsRead);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<void> deleteNotification(int id) async {
    try {
      await _dioClient.delete(ApiEndpoints.deleteNotification(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

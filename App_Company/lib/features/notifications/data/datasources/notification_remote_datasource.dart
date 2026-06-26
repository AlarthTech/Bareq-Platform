import '../../../../core/constants/api_constants.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../models/notification_model.dart';
import 'package:dio/dio.dart';

abstract class NotificationRemoteDataSource {
  Future<PagedResult<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
  });

  Future<int> getUnreadCount();

  Future<void> markAsRead(int notificationId);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(int notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<PagedResult<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.getMyNotifications,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.statusCode == 200) {
        return parsePagedResponse<NotificationModel>(
          response.data,
          NotificationModel.fromJson,
        );
      }
      throw ServerException('فشل جلب الإشعارات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب الإشعارات'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.getUnreadCount);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is int) return data;
        if (data is num) return data.toInt();
        if (data is Map<String, dynamic>) {
          final count = data['count'] ?? data['unreadCount'] ?? data['total'];
          if (count is int) return count;
          if (count is num) return count.toInt();
        }
        return 0;
      }
      throw ServerException('فشل جلب عدد الإشعارات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب عدد الإشعارات'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await apiClient.dio.patch(
        ApiConstants.markNotificationAsRead(notificationId),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل تحديد الإشعار كمقروء', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديد الإشعار كمقروء'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await apiClient.dio.patch(ApiConstants.markAllNotificationsAsRead);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل تحديد جميع الإشعارات كمقروءة', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديد جميع الإشعارات كمقروءة'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await apiClient.dio.delete(
        ApiConstants.deleteNotification(notificationId),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل حذف الإشعار', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل حذف الإشعار'),
        e.response?.statusCode,
      );
    }
  }
}

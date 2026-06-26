import '../models/booking_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class BookingRemoteDataSource {
  Future<PagedResult<BookingModel>> getBookingsByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  });
  Future<BookingModel> getBookingById(int bookingId);
  Future<void> updateBookingStatus(
    int bookingId,
    int statusValue, {
    String? rejectionReason,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient apiClient;

  BookingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PagedResult<BookingModel>> getBookingsByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  }) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getBookingsByCompany}/$companyId',
        queryParameters: pagination.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        return parsePagedResponse(
          response.data,
          (json) => BookingModel.fromJson(json),
        );
      }
      throw ServerException('فشل جلب قائمة الحجوزات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب قائمة الحجوزات'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<BookingModel> getBookingById(int bookingId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getBookingById}/$bookingId',
      );

      if (response.statusCode == 200) {
        return BookingModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('فشل جلب تفاصيل الحجز', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب تفاصيل الحجز'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> updateBookingStatus(
    int bookingId,
    int statusValue, {
    String? rejectionReason,
  }) async {
    try {
      final body = <String, dynamic>{'status': statusValue};
      if (statusValue == 5) {
        body['rejectionReason'] = rejectionReason?.trim();
      }

      final response = await apiClient.dio.patch(
        '${ApiConstants.updateBookingStatus}/$bookingId',
        data: body,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل تحديث حالة الحجز', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديث حالة الحجز'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
}

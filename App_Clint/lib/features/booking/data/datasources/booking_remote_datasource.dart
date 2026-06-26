import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/paged_list_parser.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/network/pagination_constants.dart';

abstract class BookingRemoteDataSource {
  Future<List<Map<String, dynamic>>> getWorkerWorkTypes(int workerId);
  Future<List<Map<String, dynamic>>> getWorkTypesByCompany(int companyId);
  Future<List<Map<String, dynamic>>> getAllWorkTypes();
  Future<PagedResult<Map<String, dynamic>>> getUserBookingsPage(
    int userId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });
  Future<PagedResult<Map<String, dynamic>>> getCompanyBookingsPage(
    int companyId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData);
  Future<Map<String, dynamic>> updateBookingStatus(
    int bookingId,
    int status, {
    String? rejectionReason,
  });
  Future<void> confirmWorkerArrival(int bookingId);
  Future<Map<String, dynamic>> submitReview(Map<String, dynamic> reviewData);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl(this.dioClient);

  final DioClient dioClient;

  @override
  Future<List<Map<String, dynamic>>> getWorkerWorkTypes(int workerId) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getWorkerWorkTypes(workerId),
      );
      return extractPagedItems(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWorkTypesByCompany(
    int companyId,
  ) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getWorkTypesByCompany(companyId),
      );
      return extractPagedItems(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllWorkTypes() async {
    try {
      final response = await dioClient.get(ApiEndpoints.getAllWorkTypes);
      return extractPagedItems(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<PagedResult<Map<String, dynamic>>> getUserBookingsPage(
    int userId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getUserBookings(userId),
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
        cancelToken: cancelToken,
      );
      return PagedResult.fromJsonMaps(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<PagedResult<Map<String, dynamic>>> getCompanyBookingsPage(
    int companyId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getCompanyBookings(companyId),
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
        cancelToken: cancelToken,
      );
      return PagedResult.fromJsonMaps(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    try {
      // Dio default validateStatus throws on 4xx/5xx — catch DioException for 409 body.
      final response = await dioClient.post(
        ApiEndpoints.createBooking,
        data: bookingData,
      );
      final status = response.statusCode;
      if (status != null && status != 200 && status != 201) {
        throw ServerFailure(
          'Unexpected create booking status: $status',
          status,
        );
      }
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw mapCreateBookingDioException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateBookingStatus(
    int bookingId,
    int status, {
    String? rejectionReason,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
        body['rejectionReason'] = rejectionReason.trim();
      }
      final response = await dioClient.patch(
        ApiEndpoints.updateBookingStatus(bookingId),
        data: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> confirmWorkerArrival(int bookingId) async {
    try {
      await dioClient.patch(ApiEndpoints.confirmBookingArrival(bookingId));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> submitReview(
    Map<String, dynamic> reviewData,
  ) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.submitReview,
        data: reviewData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }
}

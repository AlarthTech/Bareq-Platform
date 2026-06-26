import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../../../core/network/paged_list_parser.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/network/pagination_constants.dart';
import '../../../../core/utils/calendar_date.dart';

/// Remote data source for home feature
abstract class HomeRemoteDataSource {
  Future<PagedResult<Map<String, dynamic>>> getAvailableWorkersPaginated({
    DateTime? date,
    int? companyId,
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });

  /// Returns null when the v1 top-rated route is not deployed (HTTP 404).
  Future<PagedResult<Map<String, dynamic>>?> tryGetTopRatedWorkersPaginated({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });

  Future<PagedResult<Map<String, dynamic>>> getWorkersByCompanyPaginated(
    int companyId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });

  Future<List<Map<String, dynamic>>> getAllLanguages({
    CancelToken? cancelToken,
  });

  /// Returns null when the worker does not exist (HTTP 404).
  Future<Map<String, dynamic>?> getWorkerById(
    int id, {
    CancelToken? cancelToken,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl(this.dioClient);

  final DioClient dioClient;

  @override
  Future<PagedResult<Map<String, dynamic>>> getAvailableWorkersPaginated({
    DateTime? date,
    int? companyId,
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{
      ...paginationQuery(page: page, pageSize: pageSize),
    };
    if (date != null) {
      query['date'] = CalendarDate.formatDateOnly(date);
    }
    if (companyId != null) {
      query['companyId'] = companyId;
    }

    try {
      final response = await dioClient.get(
        ApiEndpoints.workersAvailableV1,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      return PagedResult.fromJsonMaps(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        throw mapDioExceptionToFailure(e);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }

    try {
      final response = await dioClient.get(
        ApiEndpoints.workersAvailableByDate,
        queryParameters: query,
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
  Future<PagedResult<Map<String, dynamic>>?> tryGetTopRatedWorkersPaginated({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.workersTopRatedV1,
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
        cancelToken: cancelToken,
      );
      return PagedResult.fromJsonMaps(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<PagedResult<Map<String, dynamic>>> getWorkersByCompanyPaginated(
    int companyId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getWorkersByCompany(companyId),
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
  Future<Map<String, dynamic>?> getWorkerById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getWorkerById(id),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllLanguages({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getAllLanguages,
        cancelToken: cancelToken,
      );
      return extractPagedItems(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }
}

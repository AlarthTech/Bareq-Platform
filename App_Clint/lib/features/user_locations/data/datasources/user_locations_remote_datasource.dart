import 'package:dio/dio.dart';
import '../../../../core/data/models/paged_result.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/data/parsers/paged_list_parser.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';

abstract class UserLocationsRemoteDataSource {
  Future<PagedResult<Map<String, dynamic>>> getMyLocationsPage({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });

  Future<Map<String, dynamic>> getById(int id);
  Future<Map<String, dynamic>> create(Map<String, dynamic> body);
  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body);
  Future<void> delete(int id);
}

class UserLocationsRemoteDataSourceImpl implements UserLocationsRemoteDataSource {
  UserLocationsRemoteDataSourceImpl(this.dioClient);

  final DioClient dioClient;

  @override
  Future<PagedResult<Map<String, dynamic>>> getMyLocationsPage({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getMyLocations,
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
        cancelToken: cancelToken,
      );
      return PagedResult.fromJsonMaps(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getById(int id) async {
    try {
      final response = await dioClient.get(ApiEndpoints.getUserLocationById(id));
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.createUserLocation,
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
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    try {
      final response = await dioClient.put(
        ApiEndpoints.updateUserLocation(id),
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
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await dioClient.delete(ApiEndpoints.deleteUserLocation(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

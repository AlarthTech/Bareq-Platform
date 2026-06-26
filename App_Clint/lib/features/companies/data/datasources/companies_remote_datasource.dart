import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../../../core/network/paged_list_parser.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/network/pagination_constants.dart';

abstract class CompaniesRemoteDataSource {
  Future<PagedResult<Map<String, dynamic>>> getAllCompaniesPaginated({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  });

  Future<Map<String, dynamic>> getCompanyById(
    int id, {
    CancelToken? cancelToken,
  });
}

class CompaniesRemoteDataSourceImpl implements CompaniesRemoteDataSource {
  final DioClient dioClient;

  CompaniesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<PagedResult<Map<String, dynamic>>> getAllCompaniesPaginated({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getAllCompanies,
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
  Future<Map<String, dynamic>> getCompanyById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.getCompanyById(id),
        cancelToken: cancelToken,
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

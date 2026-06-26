import 'package:dio/dio.dart';

import '../../../../core/data/models/paged_result.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/data/parsers/paged_list_parser.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../models/create_report_request.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<ReportModel> createWorkerReport(int workerId, String description);

  Future<ReportModel> createCompanyReport(int companyId, String description);

  Future<PagedResult<ReportModel>> getMyReports({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  });

  Future<ReportModel> getReportById(int id);

  Future<void> deleteReport(int id);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  ReportRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<ReportModel> createWorkerReport(int workerId, String description) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.createReport,
        data: CreateWorkerReportRequest(
          workerId: workerId,
          description: description,
        ).toJson(),
      );
      return ReportModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<ReportModel> createCompanyReport(
    int companyId,
    String description,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.createReport,
        data: CreateCompanyReportRequest(
          companyId: companyId,
          description: description,
        ).toJson(),
      );
      return ReportModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<PagedResult<ReportModel>> getMyReports({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.getMyReports,
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
      );
      return PagedResult.fromJson(
        response.data,
        (json) => ReportModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<ReportModel> getReportById(int id) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.getReportById(id));
      return ReportModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<void> deleteReport(int id) async {
    try {
      await _dioClient.delete(ApiEndpoints.deleteReport(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

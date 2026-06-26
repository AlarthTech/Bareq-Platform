import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../models/rating_summary_model.dart';

abstract class RatingRemoteDataSource {
  Future<RatingSummaryModel> getWorkerSummary(int workerId);

  Future<CompanyRatingSummaryModel> getCompanySummary(int companyId);

  Future<List<WorkerRatingSummaryModel>> getCompanyWorkerSummaries(
    int companyId,
  );
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  RatingRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<RatingSummaryModel> getWorkerSummary(int workerId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.workerRatingSummary(workerId),
      );
      return RatingSummaryModel.fromJson(
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
  Future<CompanyRatingSummaryModel> getCompanySummary(int companyId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.companyRatingSummary(companyId),
      );
      return CompanyRatingSummaryModel.fromJson(
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
  Future<List<WorkerRatingSummaryModel>> getCompanyWorkerSummaries(
    int companyId,
  ) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.companyWorkerRatingSummaries(companyId),
      );
      final raw = response.data;
      if (raw is! List) return const [];
      return raw
          .map(
            (e) => WorkerRatingSummaryModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

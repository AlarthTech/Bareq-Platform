import '../../../../core/constants/api_constants.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../models/rating_summary_model.dart';
import '../models/review_model.dart';
import 'package:dio/dio.dart';

abstract class WorkerReviewsRemoteDataSource {
  Future<CompanyRatingSummaryModel> getCompanyRatingSummary(int companyId);

  Future<List<WorkerRatingSummaryModel>> getCompanyWorkerSummaries(
    int companyId,
  );

  Future<WorkerRatingSummaryModel> getWorkerRatingSummary(int workerId);

  Future<PagedResult<ReviewModel>> getWorkerReviews(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<ReviewModel> getReviewById(int reviewId);
}

class WorkerReviewsRemoteDataSourceImpl implements WorkerReviewsRemoteDataSource {
  WorkerReviewsRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<CompanyRatingSummaryModel> getCompanyRatingSummary(int companyId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.companyRatingSummary(companyId),
      );
      if (response.statusCode == 200) {
        return CompanyRatingSummaryModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException('فشل جلب ملخص تقييم الشركة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب ملخص تقييم الشركة'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<WorkerRatingSummaryModel>> getCompanyWorkerSummaries(
    int companyId,
  ) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.companyWorkerRatingSummaries(companyId),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map(
                (e) => WorkerRatingSummaryModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        return [];
      }
      throw ServerException('فشل جلب تقييمات العاملات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب تقييمات العاملات'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<WorkerRatingSummaryModel> getWorkerRatingSummary(int workerId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.workerRatingSummary(workerId),
      );
      if (response.statusCode == 200) {
        return WorkerRatingSummaryModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException('فشل جلب ملخص تقييم العاملة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب ملخص تقييم العاملة'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<PagedResult<ReviewModel>> getWorkerReviews(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.workerReviews(workerId),
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      if (response.statusCode == 200) {
        return parsePagedResponse<ReviewModel>(
          response.data,
          ReviewModel.fromJson,
        );
      }
      throw ServerException('فشل جلب مراجعات العاملة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب مراجعات العاملة'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<ReviewModel> getReviewById(int reviewId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.getReviewById(reviewId),
      );
      if (response.statusCode == 200) {
        return ReviewModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('فشل جلب تفاصيل المراجعة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب تفاصيل المراجعة'),
        e.response?.statusCode,
      );
    }
  }
}

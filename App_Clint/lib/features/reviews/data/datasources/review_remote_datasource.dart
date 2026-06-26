import 'package:dio/dio.dart';

import '../../../../core/data/models/paged_result.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../models/create_review_request.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<ReviewModel> createReview(CreateReviewRequest request);

  Future<void> updateReview(int reviewId, UpdateReviewRequest request);

  Future<void> deleteReview(int reviewId);

  Future<PagedResult<ReviewModel>> getReviewsByWorker(
    int workerId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = 20,
  });

  Future<PagedResult<ReviewModel>> getReviewsByBooking(
    int bookingId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = 20,
  });

  Future<ReviewModel> getReviewById(int id);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  ReviewRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<ReviewModel> createReview(CreateReviewRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.createReview,
        data: request.toJson(),
      );
      return ReviewModel.fromJson(
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
  Future<void> updateReview(int reviewId, UpdateReviewRequest request) async {
    try {
      await _dioClient.patch(
        ApiEndpoints.updateReview(reviewId),
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    try {
      await _dioClient.delete(ApiEndpoints.deleteReview(reviewId));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<PagedResult<ReviewModel>> getReviewsByWorker(
    int workerId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reviewsByWorker(workerId),
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data,
        ReviewModel.fromJson,
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<PagedResult<ReviewModel>> getReviewsByBooking(
    int bookingId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.reviewsByBooking(bookingId),
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data,
        ReviewModel.fromJson,
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<ReviewModel> getReviewById(int id) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.getReviewById(id),
      );
      return ReviewModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

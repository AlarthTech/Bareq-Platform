import 'package:dio/dio.dart';

import '../../../../core/data/models/paged_result.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/data/parsers/paged_list_parser.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../models/booking_report_model.dart';

abstract class BookingReportRemoteDataSource {
  Future<BookingReportModel> createBookingReport({
    required int bookingId,
    required String reason,
    String? description,
  });

  Future<PagedResult<BookingReportModel>> getMyBookingReports({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  });

  Future<PagedResult<BookingReportModel>> getReportsByBookingId({
    required int bookingId,
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  });
}

class BookingReportRemoteDataSourceImpl implements BookingReportRemoteDataSource {
  BookingReportRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<BookingReportModel> createBookingReport({
    required int bookingId,
    required String reason,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{
        'bookingId': bookingId,
        'reason': reason.trim(),
      };
      final trimmedDescription = description?.trim();
      if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
        data['description'] = trimmedDescription;
      }

      final response = await _dioClient.post(
        ApiEndpoints.createBookingReport,
        data: data,
      );
      return BookingReportModel.fromJson(
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
  Future<PagedResult<BookingReportModel>> getMyBookingReports({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.myBookingReports,
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
      );
      return PagedResult.fromJson(
        response.data,
        (json) => BookingReportModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }

  @override
  Future<PagedResult<BookingReportModel>> getReportsByBookingId({
    required int bookingId,
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.bookingReportsByBookingId(bookingId),
        queryParameters: paginationQuery(page: page, pageSize: pageSize),
      );
      return PagedResult.fromJson(
        response.data,
        (json) => BookingReportModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

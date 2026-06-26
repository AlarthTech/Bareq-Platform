import '../../../../core/constants/api_constants.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../domain/entities/booking_report.dart';
import '../models/booking_report_model.dart';
import 'package:dio/dio.dart';

abstract class BookingReportRemoteDataSource {
  Future<PagedResult<BookingReportModel>> getCompanyBookingReports({
    BookingReportFilters? filters,
    int page = 1,
    int pageSize = 20,
  });

  Future<BookingReportModel> getBookingReportById(int id);

  Future<BookingReportModel> updateBookingReportStatus({
    required int id,
    required int status,
    String? adminResolutionNotes,
  });
}

class BookingReportRemoteDataSourceImpl implements BookingReportRemoteDataSource {
  BookingReportRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _buildQuery({
    BookingReportFilters? filters,
    required int page,
    required int pageSize,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (filters?.status != null) query['status'] = filters!.status;
    if (filters?.bookingId != null) query['bookingId'] = filters!.bookingId;
    if (filters?.customerId != null) query['customerId'] = filters!.customerId;
    if (filters?.workerId != null) query['workerId'] = filters!.workerId;
    if (filters?.fromDate != null) {
      query['fromDate'] =
          filters!.fromDate!.toIso8601String().split('T').first;
    }
    if (filters?.toDate != null) {
      query['toDate'] = filters!.toDate!.toIso8601String().split('T').first;
    }
    return query;
  }

  @override
  Future<PagedResult<BookingReportModel>> getCompanyBookingReports({
    BookingReportFilters? filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.bookingReports,
        queryParameters: _buildQuery(
          filters: filters,
          page: page,
          pageSize: pageSize,
        ),
      );
      if (response.statusCode == 200) {
        return parsePagedResponse(
          response.data,
          BookingReportModel.fromJson,
        );
      }
      throw ServerException('فشل جلب بلاغات الحجوزات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب بلاغات الحجوزات'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<BookingReportModel> getBookingReportById(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.bookingReportById(id),
      );
      if (response.statusCode == 200) {
        return BookingReportModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException('فشل جلب تفاصيل البلاغ', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب تفاصيل البلاغ'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<BookingReportModel> updateBookingReportStatus({
    required int id,
    required int status,
    String? adminResolutionNotes,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (adminResolutionNotes != null &&
          adminResolutionNotes.trim().isNotEmpty) {
        body['adminResolutionNotes'] = adminResolutionNotes.trim();
      }

      final response = await _apiClient.dio.patch(
        ApiConstants.updateBookingReportStatus(id),
        data: body,
      );
      if (response.statusCode == 200) {
        return BookingReportModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException('فشل تحديث حالة البلاغ', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديث حالة البلاغ'),
        e.response?.statusCode,
      );
    }
  }
}

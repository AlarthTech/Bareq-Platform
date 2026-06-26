import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../models/booking_price_preview_model.dart';
import '../models/booking_price_preview_request_model.dart';

abstract class BookingPricingRemoteDataSource {
  Future<BookingPricePreviewModel> previewPrice(
    BookingPricePreviewRequestModel request,
  );
}

class BookingPricingRemoteDataSourceImpl
    implements BookingPricingRemoteDataSource {
  BookingPricingRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<BookingPricePreviewModel> previewPrice(
    BookingPricePreviewRequestModel request,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.bookingPricePreview,
        data: request.toJson(),
      );
      final data = response.data;
      if (data is! Map) {
        throw const ValidationFailure('Invalid price preview response.');
      }
      return BookingPricePreviewModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(e.toString());
    }
  }
}

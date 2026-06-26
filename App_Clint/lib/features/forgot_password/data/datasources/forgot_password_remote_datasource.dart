import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/forgot_password_failure_mapper.dart';
import '../../domain/constants/forgot_password_constants.dart';
import '../models/forgot_password_requests.dart';

abstract class ForgotPasswordRemoteDataSource {
  Future<String> requestOtp(String identifier);

  Future<String> verifyResetCode({
    required String identifier,
    required String code,
  });

  Future<String> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
  });
}

class ForgotPasswordRemoteDataSourceImpl
    implements ForgotPasswordRemoteDataSource {
  ForgotPasswordRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<String> requestOtp(String identifier) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.forgotPassword,
        data: ForgotPasswordRequest(email: identifier).toJson(),
      );
      return _extractMessage(response.data) ??
          ForgotPasswordConstants.genericOtpSentMessageAr;
    } on DioException catch (e) {
      throw mapForgotPasswordDioException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<String> verifyResetCode({
    required String identifier,
    required String code,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.verifyResetCode,
        data: VerifyResetCodeRequest(email: identifier, code: code).toJson(),
      );
      final data = response.data;
      if (data is Map) {
        final token = data['resetToken']?.toString().trim();
        if (token != null && token.isNotEmpty) return token;
      }
      throw const ServerFailure(
        'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
      );
    } on DioException catch (e) {
      throw mapForgotPasswordDioException(e, otpStep: true);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<String> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.resetPassword,
        data: ResetPasswordRequest(
          email: identifier,
          resetToken: resetToken,
          newPassword: newPassword,
        ).toJson(),
      );
      return _extractMessage(response.data) ??
          'تم تغيير كلمة المرور بنجاح.';
    } on DioException catch (e) {
      throw mapForgotPasswordDioException(e, resetStep: true);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      for (final key in ['message', 'Message', 'detail', 'title']) {
        final v = data[key]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }
}

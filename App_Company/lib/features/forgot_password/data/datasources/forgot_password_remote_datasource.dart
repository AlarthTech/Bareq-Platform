import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class ForgotPasswordRemoteDataSource {
  Future<String> requestOtp(String email);
  Future<String> verifyCode(String email, String code);
  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  });
}

class ForgotPasswordRemoteDataSourceImpl implements ForgotPasswordRemoteDataSource {
  ForgotPasswordRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  Map<String, dynamic> _companyBody(Map<String, dynamic> fields) {
    return {...fields, 'userType': ForgotPasswordConstants.userType};
  }

  String _messageFrom(dynamic data, String fallback) {
    return dioErrorMessage(data, fallback);
  }

  @override
  Future<String> requestOtp(String email) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.forgotPassword,
        data: _companyBody({'email': email.trim().toLowerCase()}),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data['message'] as String? ??
              'إذا كان البريد الإلكتروني مسجلاً لدينا، سيتم إرسال رمز التحقق.';
        }
        return 'إذا كان البريد الإلكتروني مسجلاً لدينا، سيتم إرسال رمز التحقق.';
      }
      throw ServerException('فشل إرسال رمز التحقق', response.statusCode);
    } on DioException catch (e) {
      throw _mapDio(e, 'فشل إرسال رمز التحقق');
    }
  }

  @override
  Future<String> verifyCode(String email, String code) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.verifyResetCode,
        data: _companyBody({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        }),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final token = data['resetToken'] as String?;
          if (token != null && token.isNotEmpty) return token;
        }
        throw const ServerException('لم يُستلم رمز إعادة التعيين من الخادم');
      }
      throw ServerException('فشل التحقق من الرمز', response.statusCode);
    } on DioException catch (e) {
      throw _mapDio(e, 'رمز التحقق غير صحيح أو منتهي الصلاحية');
    }
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.resetPassword,
        data: _companyBody({
          'email': email.trim().toLowerCase(),
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data['message'] as String? ?? 'تم تغيير كلمة المرور بنجاح.';
        }
        return 'تم تغيير كلمة المرور بنجاح.';
      }
      throw ServerException('فشل إعادة تعيين كلمة المرور', response.statusCode);
    } on DioException catch (e) {
      throw _mapDio(e, 'رمز إعادة التعيين غير صالح أو منتهي الصلاحية');
    }
  }

  ServerException _mapDio(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 429) {
      throw const RateLimitException(
        'تجاوزت الحد المسموح من المحاولات. يرجى المحاولة بعد ساعة.',
      );
    }
    return ServerException(
      _messageFrom(e.response?.data, fallback),
      status,
    );
  }
}

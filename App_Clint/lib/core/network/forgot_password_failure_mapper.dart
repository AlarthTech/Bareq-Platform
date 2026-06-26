import 'package:dio/dio.dart';

import '../error/failures.dart';
import 'dio_failure_mapper.dart';
import 'problem_details_parser.dart';

/// Maps Dio errors for forgot-password OTP flow with Arabic-friendly messages.
Failure mapForgotPasswordDioException(
  DioException e, {
  bool otpStep = false,
  bool resetStep = false,
}) {
  final status = e.response?.statusCode;
  final fromBody = extractDioResponseMessage(e.response);

  if (status == 429) {
    return RateLimitFailure(
      fromBody ??
          'تم إرسال عدد كبير من الطلبات، يرجى المحاولة بعد قليل.',
    );
  }
  if (status == 401) {
    return AuthFailure(
      fromBody ?? 'غير مصرح. يرجى المحاولة مرة أخرى.',
    );
  }
  if (status == 400) {
    if (otpStep) {
      return ValidationFailure(
        fromBody ?? 'رمز التحقق غير صحيح أو منتهي الصلاحية.',
      );
    }
    if (resetStep) {
      return ValidationFailure(
        fromBody ?? 'رمز إعادة التعيين غير صالح أو منتهي الصلاحية.',
      );
    }
    return ValidationFailure(
      fromBody ??
          'تعذر إتمام الطلب. يرجى التحقق من البيانات والمحاولة مرة أخرى.',
    );
  }
  if (status != null && status >= 500) {
    return ServerFailure(
      fromBody ?? 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
      status,
    );
  }
  return mapDioExceptionToFailure(e);
}

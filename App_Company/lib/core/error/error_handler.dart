import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import '../error/failures.dart';

class ErrorHandler {
  static Failure handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is ServerException) {
      return _mapServerException(error);
    } else if (error is NetworkException) {
      return NetworkFailure(error.message);
    } else if (error is CacheException) {
      return CacheFailure(error.message);
    } else if (error is ValidationException) {
      return ValidationFailure(error.message);
    } else if (error is UnauthorizedException) {
      return UnauthorizedFailure(error.message);
    } else if (error is ForbiddenException) {
      return ForbiddenFailure(error.message);
    } else if (error is RateLimitException) {
      return RateLimitFailure(error.message);
    } else if (error is NotFoundException) {
      return NotFoundFailure(error.message);
    } else if (error is ActiveBookingsException) {
      return ActiveBookingsFailure(error.message);
    } else {
      return UnknownFailure('حدث خطأ غير متوقع: ${error.toString()}');
    }
  }

  static Failure _mapServerException(ServerException error) {
    switch (error.statusCode) {
      case 400:
        return ValidationFailure(error.message);
      case 401:
        return UnauthorizedFailure('غير مصرح لك. يرجى تسجيل الدخول مرة أخرى');
      case 403:
        return ForbiddenFailure('لا تملك صلاحية');
      case 404:
        return NotFoundFailure(error.message);
      case 409:
        return ActiveBookingsFailure(error.message);
      case 429:
        return RateLimitFailure('حاول لاحقاً');
      case 500:
      case 502:
      case 503:
        return ServerFailure('خطأ في الخادم. يرجى المحاولة لاحقاً');
      default:
        return ServerFailure(error.message);
    }
  }

  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          'استغرق الخادم وقتاً طويلاً للرد. '
          'إذا كنت تنشئ شركة، تحقق من قائمة الشركات قبل إعادة المحاولة.',
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return NetworkFailure('تم إلغاء الطلب');

      case DioExceptionType.connectionError:
        return NetworkFailure('فشل الاتصال بالخادم. تحقق من اتصالك بالإنترنت');

      case DioExceptionType.badCertificate:
        return NetworkFailure('خطأ في شهادة الاتصال');

      case DioExceptionType.unknown:
        return NetworkFailure('حدث خطأ في الاتصال: ${error.message ?? 'خطأ غير معروف'}');
    }
  }

  static Failure _handleResponseError(Response? response) {
    if (response == null) {
      return ServerFailure('لا توجد استجابة من الخادم');
    }

    final statusCode = response.statusCode;
    final message = _extractErrorMessage(response.data) ?? 'حدث خطأ في الخادم';

    switch (statusCode) {
      case 400:
        return ValidationFailure(message);
      case 401:
        return UnauthorizedFailure('غير مصرح لك. يرجى تسجيل الدخول مرة أخرى');
      case 403:
        return ForbiddenFailure('لا تملك صلاحية');
      case 404:
        return NotFoundFailure('المورد المطلوب غير موجود');
      case 409:
        return ActiveBookingsFailure(message);
      case 429:
        return RateLimitFailure('حاول لاحقاً');
      case 500:
      case 502:
      case 503:
        return ServerFailure('خطأ في الخادم. يرجى المحاولة لاحقاً');
      default:
        return ServerFailure(message);
    }
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['Message'] as String? ??
          data['Error'] as String? ??
          data['detail'] as String? ??
          data['Detail'] as String? ??
          data['title'] as String? ??
          data['Title'] as String?;
    }

    if (data is String) {
      return data;
    }

    return null;
  }

  static String getErrorMessage(Failure failure) {
    return failure.message;
  }
}

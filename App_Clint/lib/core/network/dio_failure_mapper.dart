import 'package:dio/dio.dart';

import '../error/failures.dart';
import '../../features/wallet/data/utils/wallet_error_parser.dart';
import 'problem_details_parser.dart';

export 'problem_details_parser.dart' show parseProblemDetail, parseApiErrorMessage;

/// RFC 7807 ProblemDetails + common API error shapes.
String? extractDioResponseMessage(Response<dynamic>? response) {
  if (response == null) return null;
  final data = response.data;
  if (data is Map) {
    final m = Map<String, dynamic>.from(data);
    // ProblemDetails (500): prefer detail, then title
    final detail = m['detail']?.toString().trim();
    if (detail != null && detail.isNotEmpty) return detail;
    final title = m['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    for (final key in ['message', 'error', 'Message', 'errors']) {
      final v = m[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();
  return null;
}

/// Maps [DioException] to domain [Failure] types with status-specific messaging.
Failure mapDioExceptionToFailure(DioException e) {
  final status = e.response?.statusCode;
  final fromBody = extractDioResponseMessage(e.response);

  if (status == 403) {
    return ForbiddenFailure(
      fromBody ??
          'You do not have permission for this action. Please contact support if you need help.',
    );
  }
  if (status == 401) {
    return const AuthFailure('Your session has expired. Please sign in again.');
  }
  if (status == 409) {
    return BookingConflictFailure(
      extractProblemDetailsDetail(e.response) ??
          fromBody ??
          'هذه العاملة غير متاحة في هذا الموعد، يرجى اختيار عاملة أخرى أو موعد مختلف.',
    );
  }
  if (status == 429) {
    return RateLimitFailure(
      fromBody ??
          'تم إرسال عدد كبير من الطلبات، يرجى المحاولة بعد قليل.',
    );
  }
  if (status == 404) {
    return NotFoundFailure(fromBody ?? 'The requested resource was not found.');
  }
  if (status == 400) {
    return ValidationFailure(
      fromBody ?? 'Invalid request. Please check your input and try again.',
    );
  }
  if (status != null && status >= 500) {
    return ServerFailure(
      fromBody ??
          'Server error. Please try again in a few moments.',
      status,
    );
  }
  if (e.response != null) {
    final msg =
        fromBody ??
        e.response?.statusMessage ??
        'Server error: ${e.response?.statusCode}';
    return ServerFailure(msg, status);
  }
  return NetworkFailure(e.message ?? 'Network error occurred');
}

/// Maps Dio errors from POST /api/Bookings/CreateBooking (409 must not become [ServerFailure]).
Failure mapCreateBookingDioException(DioException e) {
  final status = e.response?.statusCode;
  final body = e.response?.data;

  if (status == 409) {
    return BookingConflictFailure(
      parseProblemDetail(body) ??
          'العاملة محجوزة بالفعل في هذا اليوم.',
    );
  }
  if (status == 400) {
    final walletFailure = parseWalletFailureFromBody(body);
    if (walletFailure != null) return walletFailure;

    final bodyText = body?.toString() ?? '';
    if (bodyText.contains('المستخدم غير موجود')) {
      return const AuthFailure('Session invalid. Please login again.');
    }
    return ValidationFailure(
      parseApiErrorMessage(body) ??
          'تعذر إتمام الحجز. يرجى التحقق من البيانات والمحاولة مرة أخرى.',
    );
  }
  if (status == 401) {
    return const AuthFailure('Your session has expired. Please sign in again.');
  }
  if (status == 429) {
    return RateLimitFailure(
      parseApiErrorMessage(body) ??
          'تم إرسال عدد كبير من الطلبات، يرجى المحاولة بعد قليل.',
    );
  }
  if (status != null && status >= 500) {
    return ServerFailure(
      parseApiErrorMessage(body) ??
          'Server error. Please try again in a few moments.',
      status,
    );
  }
  return mapDioExceptionToFailure(e);
}

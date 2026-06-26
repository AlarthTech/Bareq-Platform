import 'package:dio/dio.dart';

/// Best-effort message from Dio error response bodies (ASP.NET ProblemDetails, etc.).
String dioErrorMessage(dynamic data, String fallback) {
  if (data == null) return fallback;
  if (data is String) {
    final t = data.trim();
    return t.isNotEmpty ? t : fallback;
  }
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    for (final key in ['detail', 'Detail', 'title', 'Title']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        final item = first.first;
        if (item is String && item.trim().isNotEmpty) return item.trim();
      }
    }
  }
  return fallback;
}

/// User-facing message for upload / connection failures (incl. web XHR errors).
String dioUploadErrorMessage(DioException e, String fallback) {
  final fromBody = dioErrorMessage(e.response?.data, '');
  if (fromBody.isNotEmpty) return fromBody;

  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'انقطع الاتصال أثناء رفع الملف. تحقق من الإنترنت وحاول مرة أخرى، أو استخدم ملفاً أصغر.';
    default:
      return fallback;
  }
}

import 'package:dio/dio.dart';

/// Parses RFC 7807 ProblemDetails and ASP.NET validation payloads.
String? parseProblemDetail(dynamic data) {
  if (data == null) return null;
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final detail = map['detail'];
    if (detail != null && detail.toString().trim().isNotEmpty) {
      return detail.toString().trim();
    }
    final title = map['title'];
    if (title != null && title.toString().trim().isNotEmpty) {
      return title.toString().trim();
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();
  return null;
}

/// Best-effort user message from error response (400 validation, etc.).
String? parseApiErrorMessage(dynamic data) {
  final fromProblem = parseProblemDetail(data);
  if (fromProblem != null) return fromProblem;
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in ['message', 'error', 'Message', 'errors']) {
      final v = map[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();
  return null;
}

String? extractProblemDetailsDetail(Response<dynamic>? response) {
  return parseProblemDetail(response?.data);
}

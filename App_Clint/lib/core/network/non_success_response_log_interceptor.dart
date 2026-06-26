import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only: logs API responses when status is not 200, plus all errors.
class NonSuccessResponseLogInterceptor extends Interceptor {
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode;
    if (status != null && status != 200) {
      _logResponse(response.requestOptions, status, response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _logResponse(
      err.requestOptions,
      status,
      err.response?.data ?? err.message,
    );
    handler.next(err);
  }

  void _logResponse(RequestOptions options, int? status, Object? body) {
    debugPrint(
      '*** HTTP ${status ?? '—'} ${options.method} ${options.uri}',
    );
    if (body != null) {
      debugPrint('*** Response: $body');
    }
  }
}

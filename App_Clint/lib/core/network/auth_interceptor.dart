import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';

import '../auth/secure_token_storage.dart';
import '../constants/app_strings.dart';
import '../routing/app_router.dart';
import 'public_api_paths.dart';

typedef OnUnauthorized = Future<void> Function();

/// Injects `Authorization: Bearer …` for non-public routes; clears session on 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureTokenStorage tokenStorage,
    required OnUnauthorized onUnauthorized,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized;

  final SecureTokenStorage _tokenStorage;
  final OnUnauthorized _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    if (!PublicApiPaths.isPublicPath(path)) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.uri.path;
      if (!PublicApiPaths.isPublicPath(path)) {
        await _onUnauthorized();
        _scheduleLoginNavigation();
      }
    }
    handler.next(err);
  }

  void _scheduleLoginNavigation() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        AppRouter.router.go(AppStrings.routeLogin);
      }
    });
  }
}

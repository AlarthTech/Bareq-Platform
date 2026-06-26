import 'package:dio/dio.dart';

typedef UnauthorizedHandler = void Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.onUnauthorized});

  final UnauthorizedHandler? onUnauthorized;

  static const _publicAuthPaths = [
    '/AppUsers/Login',
    '/AppUsers/CreateNewCompanyOwner',
    '/AppUsers/ForgotPassword',
    '/AppUsers/VerifyResetCode',
    '/AppUsers/ResetPassword',
  ];

  bool _isPublicAuthRequest(RequestOptions options) {
    final path = options.path;
    return _publicAuthPaths.any(path.endsWith);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_isPublicAuthRequest(err.requestOptions)) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}

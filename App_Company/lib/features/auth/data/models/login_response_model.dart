import 'user_model.dart';

class LoginResponseModel {
  final bool success;
  final UserModel? user;
  final String? message;
  final String? token;

  const LoginResponseModel({
    required this.success,
    this.user,
    this.message,
    this.token,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? json['accessToken'] ?? json['jwt']) as String?;
    final userJson = json['user'];
    final hasToken = token != null && token.trim().isNotEmpty;
    final hasUser = userJson is Map<String, dynamic>;
    return LoginResponseModel(
      success: json['success'] as bool? ?? (hasToken && hasUser),
      user: hasUser ? UserModel.fromJson(userJson) : null,
      message: json['message'] as String? ?? json['Message'] as String?,
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user?.toJson(),
      'message': message,
      'token': token,
    };
  }
}

import '../../domain/constants/forgot_password_constants.dart';

class ForgotPasswordRequest {
  ForgotPasswordRequest({
    required this.email,
    this.userType = ForgotPasswordConstants.userTypeCustomer,
  });

  /// API field name is `email` — accepts email OR phone.
  final String email;
  final String userType;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'userType': userType,
      };
}

class VerifyResetCodeRequest {
  VerifyResetCodeRequest({
    required this.email,
    required this.code,
    this.userType = ForgotPasswordConstants.userTypeCustomer,
  });

  final String email;
  final String code;
  final String userType;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'code': code.trim(),
        'userType': userType,
      };
}

class ResetPasswordRequest {
  ResetPasswordRequest({
    required this.email,
    required this.resetToken,
    required this.newPassword,
    this.userType = ForgotPasswordConstants.userTypeCustomer,
  });

  final String email;
  final String resetToken;
  final String newPassword;
  final String userType;

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'resetToken': resetToken,
        'newPassword': newPassword,
        'userType': userType,
      };
}

/// Navigation extra for [ResetPasswordPage].
class ForgotPasswordResetExtra {
  const ForgotPasswordResetExtra({
    required this.email,
    required this.resetToken,
  });

  final String email;
  final String resetToken;
}

import 'email_validator.dart';

/// Validates login-style identifier: email OR phone (same rules as sign-in).
class LoginIdentifierValidator {
  LoginIdentifierValidator._();

  static bool isValid(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (EmailValidator.isValid(trimmed)) return true;
    return _isValidPhone(trimmed);
  }

  static bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+')) {
      return RegExp(r'^\+\d{8,15}$').hasMatch(digits);
    }
    return RegExp(r'^\d{8,15}$').hasMatch(digits);
  }
}

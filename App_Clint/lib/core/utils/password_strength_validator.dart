/// Password rules for forgot-password reset (min 8 + upper + lower + digit).
class PasswordStrengthValidator {
  PasswordStrengthValidator._();

  static bool hasMinLength(String value, {int min = 8}) =>
      value.length >= min;

  static bool hasUppercase(String value) =>
      value.contains(RegExp(r'[A-Z]'));

  static bool hasLowercase(String value) =>
      value.contains(RegExp(r'[a-z]'));

  static bool hasDigit(String value) => value.contains(RegExp(r'[0-9]'));

  static bool isStrong(String value) =>
      hasMinLength(value) &&
      hasUppercase(value) &&
      hasLowercase(value) &&
      hasDigit(value);
}

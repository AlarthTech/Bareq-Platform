import 'package:flutter/services.dart';

/// Shared phone input rules for Libyan customer numbers (max 10 digits).
abstract final class PhoneInputConstraints {
  static const int minLength = 8;
  static const int maxLength = 10;

  static List<TextInputFormatter> get formatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ];

  static String? validate(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return invalidMessage;
    }
    return null;
  }

  static bool isValid(String value) =>
      validate(
        value,
        requiredMessage: '',
        invalidMessage: 'x',
      ) ==
      null;
}

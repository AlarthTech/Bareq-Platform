/// Lightweight email validation for forms (not RFC-complete).
class EmailValidator {
  EmailValidator._();

  static final RegExp _pattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static bool isValid(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return _pattern.hasMatch(trimmed);
  }
}

/// Client-side validation for report descriptions.
class ReportDescriptionValidator {
  ReportDescriptionValidator._();

  static const int minLength = 10;
  static const int maxLength = 2000;

  static String? validate(String? value, {String? requiredMessage, String? tooShortMessage, String? tooLongMessage}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredMessage ?? 'Description is required';
    if (text.length < minLength) {
      return tooShortMessage ?? 'Description must be at least $minLength characters';
    }
    if (text.length > maxLength) {
      return tooLongMessage ?? 'Description must be at most $maxLength characters';
    }
    return null;
  }
}

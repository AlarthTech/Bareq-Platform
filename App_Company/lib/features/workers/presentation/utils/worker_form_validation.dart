import '../../../../core/constants/app_constants.dart';

/// Client-side validation for the add-worker form.
class WorkerFormValidation {
  WorkerFormValidation._();

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال العمر';
    }
    final age = int.tryParse(value.trim());
    if (age == null) return 'يرجى إدخال رقم صحيح';
    if (age < AppConstants.workerMinAge) {
      return 'الحد الأدنى للعمر ${AppConstants.workerMinAge} سنة';
    }
    if (age > AppConstants.workerMaxAge) {
      return 'الحد الأقصى للعمر ${AppConstants.workerMaxAge} سنة';
    }
    return null;
  }

  /// [age] is the parsed worker age; experience must be non-negative and strictly less than age.
  static String? validateExperienceYears(String? value, {int? age}) {
    if (value == null || value.trim().isEmpty) return null;

    final years = int.tryParse(value.trim());
    if (years == null) return 'يرجى إدخال رقم صحيح';
    if (years < 0) return 'لا يمكن أن تكون سنوات الخبرة سالبة';

    if (age == null) {
      return 'أدخل العمر أولاً ثم سنوات الخبرة';
    }
    if (years >= age) {
      return 'يجب أن تكون سنوات الخبرة أقل من العمر ($age)';
    }
    return null;
  }

  static int? parseAge(String raw) => int.tryParse(raw.trim());
}

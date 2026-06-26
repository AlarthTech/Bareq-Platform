class OnboardingPrefillStorage {
  OnboardingPrefillStorage._();

  static int? cityId;

  static void setCityId(int? value) => cityId = value;

  static void clear() => cityId = null;
}

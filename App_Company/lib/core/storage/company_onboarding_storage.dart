import 'package:shared_preferences/shared_preferences.dart';

class CompanyOnboardingStorage {
  CompanyOnboardingStorage._();

  static const _skipKey = 'company_creation_skipped';

  static Future<void> setSkipped(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, value);
  }

  static Future<bool> readSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipKey) ?? false;
  }

  static Future<void> clearSkipped() async {
    await setSkipped(false);
  }
}

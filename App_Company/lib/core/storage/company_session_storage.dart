import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class CompanySessionStorage {
  static Future<void> savePrimaryCompanyId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.companyIdKey, id);
  }

  static Future<int?> readPrimaryCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.companyIdKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.companyIdKey);
  }
}

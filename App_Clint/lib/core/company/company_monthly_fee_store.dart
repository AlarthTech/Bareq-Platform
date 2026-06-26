import 'package:shared_preferences/shared_preferences.dart';

/// Persists monthly accommodation/residency fees set by companies (per company id).
/// Merged with API values when present on [Company.monthlyAccommodationFee].
class CompanyMonthlyFeeStore {
  CompanyMonthlyFeeStore._();
  static CompanyMonthlyFeeStore? _instance;
  static const _keyPrefix = 'company_monthly_accommodation_fee_';
  static const _selectedCompanyKey = 'company_dashboard_selected_id';

  static CompanyMonthlyFeeStore get instance {
    _instance ??= CompanyMonthlyFeeStore._();
    return _instance!;
  }

  Future<double?> getFee(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_keyPrefix$companyId');
  }

  Future<void> setFee(String companyId, double fee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_keyPrefix$companyId', fee);
  }

  Future<String?> getSelectedCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedCompanyKey);
  }

  Future<void> setSelectedCompanyId(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCompanyKey, companyId);
  }
}

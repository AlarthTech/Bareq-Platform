import 'package:shared_preferences/shared_preferences.dart';

/// App testing toggle — uses POST /api/v1/wallet/test/bank-card-charge when on.
class WalletTestingSettings {
  WalletTestingSettings(this._prefs);

  static const String enabledKey = 'wallet_testing_mode';
  static const String balanceBonusKey = 'wallet_testing_balance_bonus';

  final SharedPreferences _prefs;

  bool get enabled => _prefs.getBool(enabledKey) ?? false;

  Future<void> setEnabled(bool value) => _prefs.setBool(enabledKey, value);

  double get balanceBonus => _prefs.getDouble(balanceBonusKey) ?? 0;

  Future<void> addBalanceBonus(double amount) async {
    if (amount <= 0) return;
    await _prefs.setDouble(balanceBonusKey, balanceBonus + amount);
  }

  Future<void> clearBalanceBonus() => _prefs.remove(balanceBonusKey);
}

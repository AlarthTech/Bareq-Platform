import 'package:shared_preferences/shared_preferences.dart';

/// Persists gateway [paymentUrl] from POST bank-card (GET status omits it).
class WalletTopUpUrlCache {
  WalletTopUpUrlCache(this._prefs);

  final SharedPreferences _prefs;

  static String _key(int topUpId) => 'wallet_top_up_payment_url_$topUpId';

  Future<void> save(int topUpId, String paymentUrl) async {
    final url = paymentUrl.trim();
    if (topUpId <= 0 || url.isEmpty) return;
    await _prefs.setString(_key(topUpId), url);
  }

  String? read(int topUpId) {
    final url = _prefs.getString(_key(topUpId))?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Future<void> remove(int topUpId) => _prefs.remove(_key(topUpId));
}

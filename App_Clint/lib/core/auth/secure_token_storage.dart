import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessTokenKey = 'cleaninghouse_access_token';

/// Persists the JWT outside of [SharedPreferences].
abstract class SecureTokenStorage {
  Future<void> writeAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

class SecureTokenStorageImpl implements SecureTokenStorage {
  SecureTokenStorageImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _kAccessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() async {
    final v = await _storage.read(key: _kAccessTokenKey);
    if (v == null || v.isEmpty) return null;
    return v;
  }

  @override
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _kAccessTokenKey);
  }
}

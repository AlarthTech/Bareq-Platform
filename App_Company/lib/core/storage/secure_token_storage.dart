import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists JWT securely when the platform plugin is available;
/// falls back to [SharedPreferences] after hot restart / unsupported platforms.
class SecureTokenStorage {
  SecureTokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static bool? _secureAvailable;

  static Future<bool> get _useSecureStorage async {
    if (_secureAvailable != null) return _secureAvailable!;

    try {
      const probeKey = '_secure_storage_probe';
      await _storage.write(key: probeKey, value: '1');
      await _storage.delete(key: probeKey);
      _secureAvailable = true;
    } on MissingPluginException {
      _secureAvailable = false;
    } on PlatformException {
      _secureAvailable = false;
    } catch (e) {
      debugPrint('SecureTokenStorage unavailable, using SharedPreferences: $e');
      _secureAvailable = false;
    }

    return _secureAvailable!;
  }

  static Future<void> saveToken(String token) async {
    if (await _useSecureStorage) {
      try {
        await _storage.write(key: AppConstants.tokenKey, value: token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.tokenKey);
        return;
      } on MissingPluginException {
        _secureAvailable = false;
      } on PlatformException {
        _secureAvailable = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  static Future<String?> readToken() async {
    if (await _useSecureStorage) {
      try {
        final secure = await _storage.read(key: AppConstants.tokenKey);
        if (secure != null && secure.isNotEmpty) return secure;
      } on MissingPluginException {
        _secureAvailable = false;
      } on PlatformException {
        _secureAvailable = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<void> clearToken() async {
    if (await _useSecureStorage) {
      try {
        await _storage.delete(key: AppConstants.tokenKey);
      } on MissingPluginException {
        _secureAvailable = false;
      } on PlatformException {
        _secureAvailable = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/jwt_claims_helper.dart';
import '../../../../core/auth/secure_token_storage.dart';
import '../../../../core/error/failures.dart';
import '../models/user_model.dart';

/// Local data source for authentication
abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getCurrentUser();
  Future<void> clearUser();
  Future<bool> isUserLoggedIn();
  Future<void> setRequiresProfileCompletion(bool value);
  Future<bool> getRequiresProfileCompletion();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _requiresProfileCompletionKey =
      'requires_profile_completion';

  AuthLocalDataSourceImpl(this._prefs, this._tokenStorage);

  final SharedPreferences _prefs;
  final SecureTokenStorage _tokenStorage;

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final token = user.token;
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.writeAccessToken(token);
      }
      final forPrefs = Map<String, dynamic>.from(user.toJson())
        ..remove('token')
        ..remove('tokenExpiration');
      await _prefs.setString(_userKey, jsonEncode(forPrefs));
      await _prefs.setBool(_isLoggedInKey, true);
    } catch (e) {
      throw CacheFailure('Failed to save user data: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson == null) {
        return null;
      }

      final map = jsonDecode(userJson) as Map<String, dynamic>;
      await _migrateLegacyTokenFromPrefsMap(map);

      final token = await _tokenStorage.readAccessToken();
      final merged = JwtClaimsHelper.applyJwtToUserMap(map, token);
      merged['token'] = token;
      return UserModel.fromJson(merged);
    } catch (e) {
      throw CacheFailure('Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> _migrateLegacyTokenFromPrefsMap(Map<String, dynamic> map) async {
    final legacy = map['token'] as String?;
    if (legacy == null || legacy.isEmpty) return;
    await _tokenStorage.writeAccessToken(legacy);
    map.remove('token');
    map.remove('tokenExpiration');
    await _prefs.setString(_userKey, jsonEncode(map));
  }

  @override
  Future<void> clearUser() async {
    try {
      await _tokenStorage.deleteAccessToken();
      await _prefs.remove(_userKey);
      await _prefs.setBool(_isLoggedInKey, false);
      await _prefs.remove(_requiresProfileCompletionKey);
    } catch (e) {
      throw CacheFailure('Failed to clear user data: ${e.toString()}');
    }
  }

  @override
  Future<void> setRequiresProfileCompletion(bool value) async {
    try {
      if (value) {
        await _prefs.setBool(_requiresProfileCompletionKey, true);
      } else {
        await _prefs.remove(_requiresProfileCompletionKey);
      }
    } catch (e) {
      throw CacheFailure(
        'Failed to save profile completion flag: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> getRequiresProfileCompletion() async {
    return _prefs.getBool(_requiresProfileCompletionKey) ?? false;
  }

  @override
  Future<bool> isUserLoggedIn() async {
    try {
      final token = await _tokenStorage.readAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/social_auth_provider.dart';

/// OAuth client IDs for Android + iOS native apps.
abstract final class SocialAuthConfig {
  /// Android / iOS idToken: OAuth **Web** client ID (serverClientId).
  /// Must be the Web client from Firebase project albarerq (starts with 106533226272-ohk9…).
  /// Copy the full value from Google Cloud → APIs & Services → Credentials → Web client.
  static const String googleWebClientId =
      '106533226272-ohk9d2tf1lvnd9i6rnacffurtichatde.apps.googleusercontent.com';

  /// iOS: OAuth **iOS** client ID → Info.plist `GIDClientID`.
  static const String googleIosClientId =
      '106533226272-i47jlocihoesvd3eujlt0h0rlog29o9r.apps.googleusercontent.com';

  static const String facebookAppId = '885865613874970';

  /// iOS App ID (Bundle ID) — must match Xcode + Apple Developer Portal.
  /// Backend validates Apple `idToken` JWT with `aud` = this value.
  static const String appleBundleId = 'ly.albareq.customerapp';

  /// Apple Developer Team ID (Certificates, Identifiers & Profiles).
  static const String appleTeamId = 'CL77WG373V';

  static const String apiBaseUrl = 'https://apialbareq.al-earth.ly';

  static bool get isGoogleConfigured {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _isRealId(googleIosClientId) && googleServerClientId != null;
    }
    return _isRealId(googleWebClientId);
  }

  /// Web client ID from the same Google Cloud project as the iOS client.
  static String get _effectiveGoogleWebClientId {
    final iosProject = googleIosClientId.split('-').first;
    if (googleWebClientId.startsWith('$iosProject-')) {
      return googleWebClientId;
    }
    return '';
  }

  /// serverClientId for GoogleSignIn — must match Firebase project albarerq.
  static String? get googleServerClientId {
    final effective = _effectiveGoogleWebClientId;
    return effective.isEmpty ? null : effective;
  }

  static bool get isFacebookConfigured => _isRealId(facebookAppId);

  static bool get isAppleConfigured => _isRealId(appleBundleId);

  static bool isProviderConfigured(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        return isGoogleConfigured;
      case SocialAuthProvider.facebook:
        return isFacebookConfigured;
      case SocialAuthProvider.apple:
        return isAppleConfigured;
    }
  }

  static String notConfiguredMessage(SocialAuthProvider provider) {
    switch (provider) {
      case SocialAuthProvider.google:
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            googleServerClientId == null) {
          return 'Google Sign-In: أضف Web client ID من مشروع albarerq في '
              'social_auth_config.dart (googleWebClientId). '
              'انسخه من Google Cloud → Credentials → Web client.';
        }
        return 'Google Sign-In غير مُعدّ بعد. ضع Client IDs في '
            'social_auth_config.dart و strings.xml (Android) و Info.plist (iOS).';
      case SocialAuthProvider.facebook:
        return 'Facebook Login غير مُعدّ بعد. ضع App ID في '
            'social_auth_config.dart و strings.xml / Info.plist.';
      case SocialAuthProvider.apple:
        return 'Sign in with Apple غير مُعدّ بعد. فعّل القدرة في Apple Developer '
            'لـ Bundle ID: $appleBundleId ثم Xcode (Runner.entitlements).';
    }
  }

  static String appleNotAvailableMessage() {
    return 'Sign in with Apple غير متاح على هذا الجهاز. '
        'يتطلب iOS 13 أو أحدث وجهاز iPhone حقيقي.';
  }

  /// Copy-paste message for backend team to enable Google JWT validation.
  static String backendGoogleHandoffMessage() {
    return '''
الموضوع: تفعيل Google Sign-In — Bareq Customer App (iOS/Android)

Base URL: $apiBaseUrl

Endpoint: POST /api/AppUsers/SocialLoginCustomer
Body (Google):
{
  "provider": 1,
  "idToken": "<Google idToken JWT>"
}

JWT validation (Google idToken):
- Validate signature via Google certs (https://www.googleapis.com/oauth2/v3/certs)
- aud MUST be the Web client ID (NOT the iOS client ID):
  $googleWebClientId
- iss: accounts.google.com or https://accounts.google.com

Firebase / Google Cloud project: albarerq (project number 106533226272)
iOS OAuth client (native app only, not for JWT aud): $googleIosClientId
''';
  }

  /// Copy-paste message for backend team to enable Apple JWT validation.
  static String backendAppleHandoffMessage() {
    return '''
الموضوع: تفعيل Apple Sign-In — Bareq Customer App (iOS)

Base URL: $apiBaseUrl

Bundle ID (iOS / JWT aud): $appleBundleId
Apple Team ID: $appleTeamId

Endpoint: POST /api/AppUsers/SocialLoginCustomer
Body (Apple):
{
  "provider": 2,
  "idToken": "<Apple identityToken JWT>",
  "fullName": "<optional — first sign-in only>"
}

JWT validation:
- iss = https://appleid.apple.com
- aud = $appleBundleId
- Verify signature via Apple JWKS

Apple Developer (mobile team):
- Enable "Sign in with Apple" on App ID: $appleBundleId
- Provisioning profile must include Sign in with Apple capability
''';
  }

  static bool _isRealId(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('YOUR_') &&
        !trimmed.contains('YOUR_');
  }
}

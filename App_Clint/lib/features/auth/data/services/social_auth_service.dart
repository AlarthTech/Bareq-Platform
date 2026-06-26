import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/social_auth_config.dart';
import '../../domain/entities/social_auth_provider.dart';
import '../models/social_sdk_result.dart';
import '../../../../core/platform/social_auth_platform.dart';

/// Native Google / Apple / Facebook sign-in (Android + iOS only).
class SocialAuthService {
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _googleClient {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: SocialAuthConfig.googleServerClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? SocialAuthConfig.googleIosClientId
          : null,
    );
  }

  Future<SocialSdkResult> signIn(SocialAuthProvider provider) async {
    if (!isSocialLoginSupported) {
      throw UnsupportedError(
        'Social login is only available on the Android and iOS apps.',
      );
    }

    switch (provider) {
      case SocialAuthProvider.google:
        return _signInGoogle();
      case SocialAuthProvider.apple:
        return _signInApple();
      case SocialAuthProvider.facebook:
        return _signInFacebook();
    }
  }

  Future<SocialSdkResult> _signInGoogle() async {
    try {
      final account = await _googleClient.signIn();
      if (account == null) {
        return const SocialSdkResult(cancelled: true);
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google sign-in did not return an id token.');
      }
      return SocialSdkResult(idToken: idToken);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Google sign-in error: $e\n$st');
      }
      rethrow;
    }
  }

  Future<SocialSdkResult> _signInApple() async {
    if (!showAppleSignInButton) {
      throw UnsupportedError('Apple Sign-In is only available on iOS.');
    }
    if (!SocialAuthConfig.isAppleConfigured) {
      throw StateError(
        SocialAuthConfig.notConfiguredMessage(SocialAuthProvider.apple),
      );
    }
    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw StateError(SocialAuthConfig.appleNotAvailableMessage());
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Apple sign-in did not return an id token.');
      }
      final given = credential.givenName?.trim() ?? '';
      final family = credential.familyName?.trim() ?? '';
      final fullName = [given, family].where((p) => p.isNotEmpty).join(' ');
      return SocialSdkResult(
        idToken: idToken,
        fullName: fullName.isEmpty ? null : fullName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SocialSdkResult(cancelled: true);
      }
      rethrow;
    }
  }

  Future<SocialSdkResult> _signInFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.cancelled) {
        return const SocialSdkResult(cancelled: true);
      }
      if (result.status != LoginStatus.success) {
        throw StateError(
          result.message ?? 'Facebook sign-in failed.',
        );
      }
      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null || accessToken.isEmpty) {
        throw StateError('Facebook sign-in did not return an access token.');
      }
      return SocialSdkResult(accessToken: accessToken);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Facebook sign-in error: $e\n$st');
      }
      rethrow;
    }
  }

  Future<void> signOutAll() async {
    if (!isSocialLoginSupported) return;
    try {
      await _googleClient.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}

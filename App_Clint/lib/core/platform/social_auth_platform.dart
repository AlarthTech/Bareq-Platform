import 'package:flutter/foundation.dart';

/// Social login is supported on Android and iOS native apps only (not web).
bool get isSocialLoginSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

bool get showAppleSignInButton {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

/// Toggle Facebook login button visibility without removing integration code.
const bool showFacebookSignInButton = false;

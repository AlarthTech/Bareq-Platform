import 'dart:convert';

/// Token validation utility
/// Framework-agnostic token validation logic
class TokenValidator {
  TokenValidator._();

  /// Check if a JWT token is expired
  /// Attempts to decode JWT and check expiration claim
  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty) {
      return true;
    }

    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        // Not a JWT, assume valid if token exists
        return false;
      }

      // Decode payload (base64url)
      final payload = parts[1];
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      // Check exp claim (expiration time as Unix timestamp)
      final exp = payloadMap['exp'] as int?;
      if (exp == null) {
        // No expiration claim, assume valid
        return false;
      }

      // Check if expired
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      // If decoding fails, assume token is valid (could be non-JWT token)
      return false;
    }
  }

  /// Check if token is valid (not expired)
  static bool isTokenValid(String? token) {
    return !isTokenExpired(token);
  }
}


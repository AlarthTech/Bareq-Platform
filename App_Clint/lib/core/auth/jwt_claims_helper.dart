import 'dart:convert';

import '../../features/auth/domain/entities/app_user_role.dart';

/// Reads claims from JWT payload (no signature verification — UI/session only).
class JwtClaimsHelper {
  JwtClaimsHelper._();

  static const _claimNameId =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
  static const _claimRole =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  static Map<String, dynamic>? decodePayload(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1];
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final jsonStr = utf8.decode(base64Url.decode(payload));
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String? nameIdentifier(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    final v =
        payload[_claimNameId] ??
        payload['nameid'] ??
        payload['sub'] ??
        payload['nameidentifier'];
    if (v == null) return null;
    return v.toString();
  }

  static int? companyId(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    final v = payload['companyId'] ?? payload['CompanyId'];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static AppUserRole? role(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    dynamic raw = payload[_claimRole] ?? payload['role'] ?? payload['Role'];
    if (raw is List) {
      for (final e in raw) {
        final r = appUserRoleFromClaim(e?.toString());
        if (r != null) return r;
      }
      return null;
    }
    return appUserRoleFromClaim(raw?.toString());
  }

  static DateTime? expiration(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    }
    return null;
  }

  /// Prefer JWT [nameidentifier] / `sub` over body `id` for the current user.
  static Map<String, dynamic> applyJwtToUserMap(
    Map<String, dynamic> map,
    String? token,
  ) {
    final out = Map<String, dynamic>.from(map);
    final payload = decodePayload(token);
    final nid = nameIdentifier(payload);
    if (nid != null && nid.isNotEmpty) {
      out['id'] = nid;
    }
    final r = role(payload);
    if (r != null) {
      out['role'] = r.name;
    }
    final exp = expiration(payload);
    if (exp != null) {
      out['tokenExpiration'] = exp.toIso8601String();
    }
    return out;
  }
}

import '../../domain/entities/app_user_role.dart';
import '../../domain/entities/user.dart';

int? _parseCityId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

/// User model for data layer
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.fullName,
    super.email,
    super.phone,
    super.cityId,
    super.token,
    super.tokenExpiration,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseExpiration(dynamic expiration) {
      if (expiration == null) return null;
      if (expiration is String) {
        try {
          return DateTime.parse(expiration);
        } catch (e) {
          return null;
        }
      }
      if (expiration is int) {
        return DateTime.fromMillisecondsSinceEpoch(expiration * 1000);
      }
      return null;
    }

    final username =
        json['username'] as String? ??
        json['userName'] as String? ??
        json['email'] as String? ??
        json['fullName'] as String? ??
        '';

    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      username: username,
      fullName: json['fullName'] as String? ?? json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      cityId: _parseCityId(json['cityId']),
      token: json['token'] as String? ?? json['accessToken'] as String?,
      tokenExpiration: parseExpiration(
        json['tokenExpiration'] ??
            json['expiresAt'] ??
            json['expires_in'],
      ),
      role: appUserRoleFromClaim(
        json['role']?.toString() ?? json['userTypeName']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      if (cityId != null) 'cityId': cityId,
      'token': token,
      'tokenExpiration': tokenExpiration?.toIso8601String(),
      if (role != null) 'role': role!.name,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    int? cityId,
    String? token,
    DateTime? tokenExpiration,
    AppUserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cityId: cityId ?? this.cityId,
      token: token ?? this.token,
      tokenExpiration: tokenExpiration ?? this.tokenExpiration,
      role: role ?? this.role,
    );
  }
}

import '../models/user_model.dart';
import '../../domain/entities/app_user_role.dart';
import '../../domain/entities/user.dart';

/// Maps API AppUserDTO to [UserModel], preserving session fields from [existing].
UserModel appUserDtoToUserModel(
  Map<String, dynamic> json,
  User existing,
) {
  return UserModel(
    id: json['id']?.toString() ?? existing.id,
    username: existing.username,
    fullName: json['fullName'] as String? ?? existing.fullName,
    email: json['email'] as String? ?? existing.email,
    phone: json['phone'] as String? ?? existing.phone,
    cityId: json['cityId'] as int? ??
        int.tryParse(json['cityId']?.toString() ?? '') ??
        existing.cityId,
    token: existing.token,
    tokenExpiration: existing.tokenExpiration,
    role: appUserRoleFromClaim(
          json['role']?.toString() ?? json['userTypeName']?.toString(),
        ) ??
        existing.role,
  );
}

/// Accepts a flat AppUserDTO or `{ user: AppUserDTO }` envelope.
Map<String, dynamic> extractAppUserDto(Map<String, dynamic> response) {
  final user = response['user'];
  if (user is Map<String, dynamic>) {
    return Map<String, dynamic>.from(user);
  }
  if (user is Map) {
    return Map<String, dynamic>.from(user);
  }
  return response;
}

import 'package:equatable/equatable.dart';

import 'app_user_role.dart';

/// User entity representing an authenticated user in the domain layer
class User extends Equatable {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? phone;
  final int? cityId;
  final String? token;
  final DateTime? tokenExpiration;
  final AppUserRole? role;

  const User({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.phone,
    this.cityId,
    this.token,
    this.tokenExpiration,
    this.role,
  });

  /// Check if token is valid (exists and not expired)
  bool get isTokenValid {
    if (token == null || token!.isEmpty) {
      return false;
    }
    
    // If no expiration date, assume token is valid if it exists
    if (tokenExpiration == null) {
      return true;
    }
    
    // Check if token is expired
    return DateTime.now().isBefore(tokenExpiration!);
  }

  @override
  List<Object?> get props =>
      [id, username, fullName, email, phone, cityId, token, tokenExpiration, role];

  bool get hasCompleteProfile =>
      phone != null &&
      phone!.trim().isNotEmpty &&
      cityId != null &&
      cityId! > 0;
}


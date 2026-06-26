import '../../domain/entities/user_entity.dart';
import '../../../../core/utils/date_formatter.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.email,
    required super.userTypeId,
    super.userTypeName,
    super.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? json['userName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      userTypeId: json['userTypeId'] as int? ?? 0,
      userTypeName: json['userTypeName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateFormatter.parseDate(json['createdAt'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'userTypeId': userTypeId,
      'userTypeName': userTypeName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      userTypeId: userTypeId,
      userTypeName: userTypeName,
      createdAt: createdAt,
    );
  }
}

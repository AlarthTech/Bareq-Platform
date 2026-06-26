import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final int userTypeId;
  final String? userTypeName;
  final DateTime? createdAt;
  
  const UserEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.userTypeId,
    this.userTypeName,
    this.createdAt,
  });
  
  @override
  List<Object?> get props => [
    id,
    fullName,
    phone,
    email,
    userTypeId,
    userTypeName,
    createdAt,
  ];
}

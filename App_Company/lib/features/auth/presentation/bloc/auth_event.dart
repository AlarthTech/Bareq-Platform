import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  
  const LoginEvent({
    required this.username,
    required this.password,
  });
  
  @override
  List<Object> get props => [username, password];
}

class RegisterEvent extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final int? cityId;

  const RegisterEvent({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    this.cityId,
  });

  @override
  List<Object?> get props => [fullName, phone, email, password, cityId];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

class UserProfileUpdatedEvent extends AuthEvent {
  final UserEntity user;

  const UserProfileUpdatedEvent(this.user);

  @override
  List<Object> get props => [user];
}

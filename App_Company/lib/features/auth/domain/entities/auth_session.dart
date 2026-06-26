import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthSession extends Equatable {
  final UserEntity user;
  final String token;

  const AuthSession({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

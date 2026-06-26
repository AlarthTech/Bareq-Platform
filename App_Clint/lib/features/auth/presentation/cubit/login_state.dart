import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Login screen states
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Logging in state
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Login success state
class LoginSuccess extends LoginState {
  final User user;

  const LoginSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

/// Error state
class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);

  @override
  List<Object?> get props => [message];
}


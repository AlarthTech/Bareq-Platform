import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/social_auth_provider.dart';

abstract class SocialLoginState extends Equatable {
  const SocialLoginState();

  @override
  List<Object?> get props => [];
}

class SocialLoginInitial extends SocialLoginState {
  const SocialLoginInitial();
}

class SocialLoginLoading extends SocialLoginState {
  const SocialLoginLoading(this.provider);

  final SocialAuthProvider provider;

  @override
  List<Object?> get props => [provider];
}

class SocialLoginSuccess extends SocialLoginState {
  const SocialLoginSuccess({
    required this.user,
    required this.requiresProfileCompletion,
  });

  final User user;
  final bool requiresProfileCompletion;

  @override
  List<Object?> get props => [user, requiresProfileCompletion];
}

class SocialLoginError extends SocialLoginState {
  const SocialLoginError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SocialLoginCancelled extends SocialLoginState {
  const SocialLoginCancelled();
}

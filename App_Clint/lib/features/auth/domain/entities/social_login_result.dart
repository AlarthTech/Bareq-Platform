import 'package:equatable/equatable.dart';

import 'user.dart';

class SocialLoginResult extends Equatable {
  const SocialLoginResult({
    required this.user,
    required this.isNewUser,
    required this.requiresProfileCompletion,
  });

  final User user;
  final bool isNewUser;
  final bool requiresProfileCompletion;

  @override
  List<Object?> get props => [user, isNewUser, requiresProfileCompletion];
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/platform/social_auth_platform.dart';
import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/services/social_auth_service.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../cubit/social_login_cubit.dart';
import '../cubit/social_login_state.dart';

/// Provides [SocialLoginCubit] and handles post-login navigation for any auth screen.
class SocialAuthScope extends StatelessWidget {
  const SocialAuthScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isSocialLoginSupported) return child;

    return BlocProvider(
      create: (_) => SocialLoginCubit(
        socialAuthService: sl<SocialAuthService>(),
        socialLoginUseCase: sl<SocialLoginUseCase>(),
      ),
      child: BlocListener<SocialLoginCubit, SocialLoginState>(
        listener: (context, state) {
          if (state is SocialLoginSuccess) {
            sl<AuthSessionNotifier>().setLoggedIn(
              state.user,
              requiresProfileCompletion: state.requiresProfileCompletion,
            );
            initializeCustomerNotificationsIfNeeded();
            if (state.requiresProfileCompletion) {
              context.go(AppStrings.routeCompleteProfile);
            } else {
              context.go(sl<AuthSessionNotifier>().postAuthHomeRoute);
            }
          } else if (state is SocialLoginError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: child,
      ),
    );
  }
}

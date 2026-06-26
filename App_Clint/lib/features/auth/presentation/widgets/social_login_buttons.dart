import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/entities/social_auth_provider.dart';
import '../cubit/social_login_cubit.dart';
import '../cubit/social_login_state.dart';
import '../../../../core/platform/social_auth_platform.dart';

/// Google / Apple / Facebook buttons — Android + iOS native apps only.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isSocialLoginSupported) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    return BlocBuilder<SocialLoginCubit, SocialLoginState>(
      builder: (context, state) {
        final loadingProvider =
            state is SocialLoginLoading ? state.provider : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n?.translate('orContinueWith') ?? 'Or continue with',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
              ],
            ),
            const SizedBox(height: 16),
            _SocialButton(
              label: l10n?.translate('continueWithGoogle') ?? 'Continue with Google',
              icon: FontAwesomeIcons.google,
              iconColor: const Color(0xFFDB4437),
              isLoading: loadingProvider == SocialAuthProvider.google,
              disabled: loadingProvider != null,
              onPressed: () => context
                  .read<SocialLoginCubit>()
                  .signIn(SocialAuthProvider.google),
            ),
            const SizedBox(height: 10),
            if (showAppleSignInButton)
              _SocialButton(
                label: l10n?.translate('continueWithApple') ?? 'Continue with Apple',
                icon: FontAwesomeIcons.apple,
                iconColor: Colors.black,
                isLoading: loadingProvider == SocialAuthProvider.apple,
                disabled: loadingProvider != null,
                onPressed: () => context
                    .read<SocialLoginCubit>()
                    .signIn(SocialAuthProvider.apple),
              ),
            if (showAppleSignInButton) const SizedBox(height: 10),
            if (showFacebookSignInButton)
              _SocialButton(
                label:
                    l10n?.translate('continueWithFacebook') ?? 'Continue with Facebook',
                icon: FontAwesomeIcons.facebook,
                iconColor: const Color(0xFF1877F2),
                isLoading: loadingProvider == SocialAuthProvider.facebook,
                disabled: loadingProvider != null,
                onPressed: () => context
                    .read<SocialLoginCubit>()
                    .signIn(SocialAuthProvider.facebook),
              ),
          ],
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
    this.isLoading = false,
    this.disabled = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: disabled || isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

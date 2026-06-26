import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/password_strength_validator.dart';
import '../cubit/forgot_password_flow_cubit.dart';
import '../cubit/reset_password_cubit.dart';
import '../cubit/reset_password_state.dart';
import '../theme/forgot_password_colors.dart';
import '../widgets/forgot_password_field_styles.dart';
import '../widgets/forgot_password_form_card.dart';
import '../widgets/forgot_password_gradient_button.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = sl<ForgotPasswordFlowCubit>();
    if (!flow.state.hasIdentifier || !flow.state.hasResetToken) {
      return const _MissingFlowRedirect();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: flow),
        BlocProvider(create: (_) => sl<ResetPasswordCubit>()),
      ],
      child: const _ResetPasswordScreenContent(),
    );
  }
}

class _MissingFlowRedirect extends StatelessWidget {
  const _MissingFlowRedirect();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(AppStrings.routeForgotPassword);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ResetPasswordScreenContent extends StatefulWidget {
  const _ResetPasswordScreenContent();

  @override
  State<_ResetPasswordScreenContent> createState() =>
      _ResetPasswordScreenContentState();
}

class _ResetPasswordScreenContentState
    extends State<_ResetPasswordScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ResetPasswordCubit>().submit(_newController.text);
  }

  Widget _passwordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required bool enabled,
    required String? Function(String?) validator,
    required bool isRTL,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      decoration: ForgotPasswordFieldStyles.decoration(
        context,
        label: label,
        hint: hint,
        prefixIcon: Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: ForgotPasswordColors.roseDark.withValues(alpha: 0.55),
          ),
          onPressed: onToggle,
        ),
      ),
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isRTL = l10n?.isRTL ?? false;

    return Scaffold(
      backgroundColor: ForgotPasswordColors.roseLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ForgotPasswordColors.roseDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.translate('resetPasswordTitle') ?? 'New password',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ForgotPasswordColors.roseDark,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
        listener: (context, state) {
          if (state is ResetPasswordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.translate('passwordResetSuccessLogin') ??
                      'تم تغيير كلمة المرور بنجاح، يمكنك الآن تسجيل الدخول.',
                ),
                backgroundColor: ForgotPasswordColors.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(AppStrings.routeLogin);
          } else if (state is ResetPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ForgotPasswordColors.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ResetPasswordLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: ForgotPasswordFormCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n?.translate('resetPasswordSubtitle') ??
                            'Choose a strong password (at least 8 characters with uppercase, lowercase, and a number).',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ForgotPasswordColors.roseDark.withValues(
                                alpha: 0.85,
                              ),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 20),
                      _passwordField(
                        context: context,
                        controller: _newController,
                        label:
                            l10n?.translate('newPassword') ?? 'New password',
                        hint:
                            l10n?.translate('passwordHint') ??
                                'Enter your password',
                        obscure: _obscureNew,
                        onToggle:
                            () => setState(() => _obscureNew = !_obscureNew),
                        enabled: !isLoading,
                        isRTL: isRTL,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n?.translate('passwordRequired') ??
                                'Password is required';
                          }
                          if (!PasswordStrengthValidator.isStrong(v)) {
                            return l10n?.translate('passwordWeak') ??
                                'Password must be at least 8 characters and include uppercase, lowercase, and a number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        context: context,
                        controller: _confirmController,
                        label:
                            l10n?.translate('confirmPassword') ??
                                'Confirm password',
                        hint:
                            l10n?.translate('confirmPasswordHint') ??
                                'Re-enter your password',
                        obscure: _obscureConfirm,
                        onToggle:
                            () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                        enabled: !isLoading,
                        isRTL: isRTL,
                        validator: (v) {
                          if (v != _newController.text) {
                            return l10n?.translate('passwordsDoNotMatch') ??
                                'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ForgotPasswordGradientButton(
                        label:
                            l10n?.translate('resetPasswordAction') ??
                                'Reset password',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

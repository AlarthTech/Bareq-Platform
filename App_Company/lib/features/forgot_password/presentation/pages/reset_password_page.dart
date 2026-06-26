import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/password_policy_validator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../state/forgot_password_cubit.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetToken,
  });

  final String email;
  final String resetToken;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    return PasswordPolicyValidator.validate(value ?? '');
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordCubit>().resetPassword(
          email: widget.email,
          resetToken: widget.resetToken,
          newPassword: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordResetSuccess) {
            context.go(AppRoutes.login);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final rootContext = AppRouter.rootNavigatorKey.currentContext;
              if (rootContext != null) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: ForgotPasswordConstants.tealPrimary,
                  ),
                );
              }
            });
          } else if (state is ForgotPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ForgotPasswordConstants.tealDark,
              ),
            );
            context.read<ForgotPasswordCubit>().resetToInitial();
          }
        },
        builder: (context, state) {
          final loading = state is ForgotPasswordLoading;
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFA),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: ForgotPasswordConstants.tealDark,
              title: const Text('كلمة مرور جديدة'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'اختر كلمة مرور قوية',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ForgotPasswordConstants.tealDark,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '8 أحرف على الأقل، حرف كبير، حرف صغير، ورقم واحد على الأقل',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ينتهي رمز إعادة التعيين خلال 15 دقيقة',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ForgotPasswordConstants.tealPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور الجديدة',
                        obscureText: _obscurePassword,
                        enabled: !loading,
                        validator: _validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: ForgotPasswordConstants.tealPrimary,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmController,
                        label: 'تأكيد كلمة المرور',
                        obscureText: _obscureConfirm,
                        enabled: !loading,
                        validator: _validateConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: ForgotPasswordConstants.tealPrimary,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'حفظ كلمة المرور',
                        onPressed: loading ? null : () => _submit(context),
                        isLoading: loading,
                        isFullWidth: true,
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

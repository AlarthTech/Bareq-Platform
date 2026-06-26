import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../state/forgot_password_cubit.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return 'يرجى إدخال بريد إلكتروني صحيح';
    return null;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordCubit>().requestOtp(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordOtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ForgotPasswordConstants.tealPrimary,
              ),
            );
            final email = _emailController.text.trim();
            context.push(AppRoutes.forgotPasswordVerifyRoute(email));
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
              title: const Text('نسيت كلمة المرور'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ForgotPasswordConstants.tealPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ForgotPasswordConstants.tealPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_reset_rounded,
                              size: 48,
                              color: ForgotPasswordConstants.tealPrimary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'استعادة كلمة المرور',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ForgotPasswordConstants.tealDark,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل البريد الإلكتروني المرتبط بحساب شركتك. '
                              'سنرسل لك رمز تحقق صالح لمدة 10 دقائق.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'owner@company.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        enabled: !loading,
                        onSubmitted: (_) => _submit(context),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'إرسال رمز التحقق',
                        onPressed: loading ? null : () => _submit(context),
                        isLoading: loading,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: loading ? null : () => context.pop(),
                        child: Text(
                          'العودة لتسجيل الدخول',
                          style: TextStyle(color: ForgotPasswordConstants.tealDark),
                        ),
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

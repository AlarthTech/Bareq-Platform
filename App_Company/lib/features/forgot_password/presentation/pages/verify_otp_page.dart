import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_button.dart';
import '../models/forgot_password_reset_extra.dart';
import '../state/forgot_password_cubit.dart';
import '../widgets/otp_input_field.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key, required this.email});

  final String email;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  String _otp = '';

  void _verify(BuildContext context) {
    if (_otp.length != ForgotPasswordConstants.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رمز التحقق المكوّن من 6 أرقام')),
      );
      return;
    }
    context.read<ForgotPasswordCubit>().verifyCode(
          email: widget.email,
          code: _otp,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordCodeVerified) {
            context.push(
              AppRoutes.forgotPasswordReset,
              extra: ForgotPasswordResetExtra(
                email: widget.email,
                resetToken: state.resetToken,
              ),
            );
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
              title: const Text('رمز التحقق'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أدخل رمز التحقق',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ForgotPasswordConstants.tealDark,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم إرسال رمز مكوّن من 6 أرقام إلى\n${widget.email}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ينتهي الرمز خلال 10 دقائق',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ForgotPasswordConstants.tealPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    OtpInputField(
                      enabled: !loading,
                      onCompleted: (code) {
                        setState(() => _otp = code);
                      },
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: 'تحقق',
                      onPressed: loading ? null : () => _verify(context),
                      isLoading: loading,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              context.go(
                                AppRoutes.forgotPasswordWithEmail(widget.email),
                              );
                            },
                      child: Text(
                        'إعادة إرسال الرمز',
                        style: TextStyle(color: ForgotPasswordConstants.tealDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

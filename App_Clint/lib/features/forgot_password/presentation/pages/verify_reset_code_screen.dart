import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/constants/forgot_password_constants.dart';
import '../cubit/forgot_password_flow_cubit.dart';
import '../cubit/verify_reset_code_cubit.dart';
import '../cubit/verify_reset_code_state.dart';
import '../theme/forgot_password_colors.dart';
import '../widgets/forgot_password_field_styles.dart';
import '../widgets/forgot_password_form_card.dart';
import '../widgets/forgot_password_gradient_button.dart';

class VerifyResetCodeScreen extends StatelessWidget {
  const VerifyResetCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = sl<ForgotPasswordFlowCubit>();
    if (!flow.state.hasIdentifier) {
      return const _MissingIdentifierRedirect();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: flow),
        BlocProvider(create: (_) => sl<VerifyResetCodeCubit>()),
      ],
      child: const _VerifyResetCodeScreenContent(),
    );
  }
}

class _MissingIdentifierRedirect extends StatelessWidget {
  const _MissingIdentifierRedirect();

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

class _VerifyResetCodeScreenContent extends StatefulWidget {
  const _VerifyResetCodeScreenContent();

  @override
  State<_VerifyResetCodeScreenContent> createState() =>
      _VerifyResetCodeScreenContentState();
}

class _VerifyResetCodeScreenContentState
    extends State<_VerifyResetCodeScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    context.read<VerifyResetCodeCubit>().verifyCode(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final identifier =
        context.read<ForgotPasswordFlowCubit>().state.identifier ?? '';

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
          l10n?.translate('verifyResetCodeTitle') ?? 'Verification code',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ForgotPasswordColors.roseDark,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<VerifyResetCodeCubit, VerifyResetCodeState>(
        listener: (context, state) {
          if (state is VerifyResetCodeVerified) {
            context.push(AppStrings.routeResetPassword);
          } else if (state is VerifyResetCodeResent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ForgotPasswordConstants.genericOtpSentMessageAr,
                ),
                backgroundColor: ForgotPasswordColors.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is VerifyResetCodeError) {
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
          final cubit = context.read<VerifyResetCodeCubit>();
          final isLoading = state is VerifyResetCodeLoading;
          final canResend = cubit.canResend;

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
                        l10n?.translate('verifyResetCodeSubtitle') ??
                            'Enter the 6-digit code sent to your registered email.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ForgotPasswordColors.roseDark.withValues(
                                alpha: 0.85,
                              ),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        identifier,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ForgotPasswordColors.rose,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _codeController,
                        focusNode: _codeFocus,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        enabled: !isLoading,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                              color: ForgotPasswordColors.roseDark,
                            ),
                        decoration: ForgotPasswordFieldStyles.decoration(
                          context,
                          label:
                              l10n?.translate('verificationCode') ??
                                  'Verification code',
                          hint: '000000',
                          prefixIcon: Icons.pin_outlined,
                          focused: _codeFocus.hasFocus,
                        ).copyWith(counterText: ''),
                        textDirection: TextDirection.ltr,
                        validator: (value) {
                          final code = value?.trim() ?? '';
                          if (code.isEmpty) {
                            return l10n?.translate('otpRequired') ??
                                'Verification code is required';
                          }
                          if (code.length != 6) {
                            return l10n?.translate('otpLength') ??
                                'Code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ForgotPasswordGradientButton(
                        label:
                            l10n?.translate('verifyCode') ?? 'Verify code',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _verify,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            (isLoading || !canResend)
                                ? null
                                : () => cubit.resendCode(),
                        child: Text(
                          canResend
                              ? (l10n?.translate('resendCode') ??
                                  'Resend code')
                              : (l10n?.translate('resendCodeIn') ??
                                      'Resend in {seconds}s')
                                  .replaceAll(
                                    '{seconds}',
                                    '${cubit.resendSeconds}',
                                  ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                canResend
                                    ? ForgotPasswordColors.rose
                                    : ForgotPasswordColors.roseDark.withValues(
                                      alpha: 0.5,
                                    ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () => context.go(
                                  AppStrings.routeForgotPassword,
                                ),
                        child: Text(
                          l10n?.translate('forgotPasswordRestart') ??
                              'Use a different email or phone',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ForgotPasswordColors.roseDark.withValues(
                              alpha: 0.75,
                            ),
                          ),
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

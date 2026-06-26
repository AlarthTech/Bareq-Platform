import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/login_identifier_validator.dart';
import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_flow_cubit.dart';
import '../cubit/forgot_password_state.dart';
import '../theme/forgot_password_colors.dart';
import '../widgets/forgot_password_field_styles.dart';
import '../widgets/forgot_password_form_card.dart';
import '../widgets/forgot_password_gradient_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ForgotPasswordFlowCubit>()..clear()),
        BlocProvider(create: (_) => sl<ForgotPasswordCubit>()),
      ],
      child: const _ForgotPasswordScreenContent(),
    );
  }
}

class _ForgotPasswordScreenContent extends StatefulWidget {
  const _ForgotPasswordScreenContent();

  @override
  State<_ForgotPasswordScreenContent> createState() =>
      _ForgotPasswordScreenContentState();
}

class _ForgotPasswordScreenContentState
    extends State<_ForgotPasswordScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _identifierFocus = FocusNode();

  @override
  void dispose() {
    _identifierController.dispose();
    _identifierFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ForgotPasswordCubit>().requestOtp(_identifierController.text);
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
          l10n?.translate('forgotPasswordTitle') ?? 'Forgot your password?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ForgotPasswordColors.roseDark,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordOtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.read<ForgotPasswordCubit>().genericSuccessMessage,
                ),
                backgroundColor: ForgotPasswordColors.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.push(AppStrings.routeVerifyResetCode);
          } else if (state is ForgotPasswordError) {
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
          final isLoading = state is ForgotPasswordLoading;

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
                        l10n?.translate('forgotPasswordIdentifierSubtitle') ??
                            'Enter your email or phone. The verification code will be sent to your registered email.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ForgotPasswordColors.roseDark.withValues(
                                alpha: 0.85,
                              ),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 20),
                      ListenableBuilder(
                        listenable: _identifierFocus,
                        builder: (context, _) {
                          return TextFormField(
                            controller: _identifierController,
                            focusNode: _identifierFocus,
                            keyboardType: TextInputType.text,
                            autocorrect: false,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                            decoration: ForgotPasswordFieldStyles.decoration(
                              context,
                              label: L10n.translate(context, 'emailOrPhone'),
                              hint: L10n.translate(context, 'emailOrPhoneHint'),
                              prefixIcon: Icons.person_outline,
                              focused: _identifierFocus.hasFocus,
                            ),
                            textDirection:
                                isRTL
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return L10n.translate(
                                  context,
                                  'emailOrPhoneRequired',
                                );
                              }
                              if (!LoginIdentifierValidator.isValid(value)) {
                                return L10n.translate(
                                  context,
                                  'emailOrPhoneInvalid',
                                );
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ForgotPasswordGradientButton(
                        label:
                            l10n?.translate('sendVerificationCode') ??
                                'Send verification code',
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

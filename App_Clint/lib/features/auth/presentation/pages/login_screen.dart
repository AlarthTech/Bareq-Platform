import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/save_user_usecase.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../widgets/login_floating_butterfly.dart';
import '../widgets/social_auth_scope.dart';
import '../widgets/social_login_buttons.dart';

/// Login — premium soft feminine layout, RTL-aware.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SocialAuthScope(
      child: BlocProvider(
        create: (context) => LoginCubit(
          loginUseCase: sl<LoginUseCase>(),
          saveUserUseCase: sl<SaveUserUseCase>(),
        ),
        child: const _LoginScreenContent(),
      ),
    );
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  static const Color _borderNormal = Color(0xFFE5E7EB);
  static const Color _cardBorder = Color(0xFFF3F4F6);
  static const Color _fieldFill = Color(0xFFFFFCFC);
  static const Color _placeholderColor = Color(0xFF9CA3AF);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  double _heroHeight(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    if (height < 680) return 185;
    if (height < 820) return 210;
    return 235;
  }

  void _handleLogin(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginCubit>().login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
    bool focused = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: focused ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: _placeholderColor,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color:
            focused
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.65),
        size: 22,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _borderNormal, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _borderNormal, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isRTL = l10n?.isRTL ?? false;
    final heroHeight = _heroHeight(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.gradientTop,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const _LoginBackgroundDecor(),
          Positioned(
            top: topPadding + 12,
            left: 0,
            right: 0,
            height: heroHeight + 24,
            child: IgnorePointer(
              child: LoginFloatingButterfly(areaHeight: heroHeight + 24),
            ),
          ),
          SafeArea(
            child: BlocConsumer<LoginCubit, LoginState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  sl<AuthSessionNotifier>().setLoggedIn(state.user);
                  initializeCustomerNotificationsIfNeeded();
                  context.go(sl<AuthSessionNotifier>().postAuthHomeRoute);
                } else if (state is LoginError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is LoginLoading;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: heroHeight * 0.04),
                              _LoginHero(
                                height: heroHeight,
                                asset: AppAssets.bareqLoginHero,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                    L10n.translate(context, 'welcomeBack'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  )
                                  .slideY(
                                    begin: 0.06,
                                    end: 0,
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                              const SizedBox(height: 6),
                              Text(
                                    L10n.translate(context, 'loginSubtitle'),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        height: 1.45,
                                      ),
                                    )
                                    .animate(delay: 60.ms)
                                    .fadeIn(
                                      duration: 400.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                              const SizedBox(height: 20),
                              Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(color: _cardBorder),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.06,
                                          ),
                                          blurRadius: 28,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: AppColors.border.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ListenableBuilder(
                                              listenable: _usernameFocus,
                                              builder: (context, _) {
                                                return TextFormField(
                                                  controller:
                                                      _usernameController,
                                                  focusNode: _usernameFocus,
                                                  keyboardType:
                                                      TextInputType.text,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  decoration: _fieldDecoration(
                                                    context,
                                                    label: L10n.translate(
                                                      context,
                                                      'emailOrPhone',
                                                    ),
                                                    hint: L10n.translate(
                                                      context,
                                                      'emailOrPhoneHint',
                                                    ),
                                                    prefixIcon:
                                                        Icons.person_outline,
                                                    focused:
                                                        _usernameFocus.hasFocus,
                                                  ),
                                                  textDirection:
                                                      isRTL
                                                          ? TextDirection.rtl
                                                          : TextDirection.ltr,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return L10n.translate(
                                                        context,
                                                        'emailOrPhoneRequired',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            )
                                            .animate(delay: 120.ms)
                                            .fadeIn(duration: 350.ms)
                                            .slideY(begin: 0.04, end: 0),
                                        const SizedBox(height: 14),
                                        ListenableBuilder(
                                              listenable: _passwordFocus,
                                              builder: (context, _) {
                                                return TextFormField(
                                                  controller:
                                                      _passwordController,
                                                  focusNode: _passwordFocus,
                                                  obscureText: _obscurePassword,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  decoration: _fieldDecoration(
                                                    context,
                                                    label: L10n.translate(
                                                      context,
                                                      'password',
                                                    ),
                                                    hint: L10n.translate(
                                                      context,
                                                      'passwordHint',
                                                    ),
                                                    prefixIcon:
                                                        Icons.lock_outline,
                                                    focused:
                                                        _passwordFocus.hasFocus,
                                                    suffix: IconButton(
                                                      icon: AnimatedSwitcher(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 200,
                                                            ),
                                                        child: Icon(
                                                          _obscurePassword
                                                              ? Icons
                                                                  .visibility_outlined
                                                              : Icons
                                                                  .visibility_off_outlined,
                                                          key: ValueKey(
                                                            _obscurePassword,
                                                          ),
                                                          color: AppColors
                                                              .textSecondary
                                                              .withValues(
                                                                alpha: 0.55,
                                                              ),
                                                          size: 22,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _obscurePassword =
                                                              !_obscurePassword;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  textDirection:
                                                      isRTL
                                                          ? TextDirection.rtl
                                                          : TextDirection.ltr,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return L10n.translate(
                                                        context,
                                                        'passwordRequired',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                );
                                              },
                                            )
                                            .animate(delay: 180.ms)
                                            .fadeIn(duration: 350.ms)
                                            .slideY(begin: 0.04, end: 0),
                                        const SizedBox(height: 14),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Transform.scale(
                                              scale: 0.92,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe =
                                                        value ?? false;
                                                  });
                                                },
                                                activeColor: AppColors.primary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                L10n.translate(
                                                  context,
                                                  'rememberMe',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => context.push(
                                                    AppStrings.routeForgotPassword,
                                                  ),
                                              style: TextButton.styleFrom(
                                                minimumSize: const Size(44, 40),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                foregroundColor:
                                                    AppColors.primary,
                                              ),
                                              child: Text(
                                                L10n.translate(
                                                  context,
                                                  'forgotPassword',
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ).animate(delay: 240.ms).fadeIn(duration: 350.ms),
                                        const SizedBox(height: 20),
                                        _LoginGradientButton(
                                              label: L10n.translate(
                                                context,
                                                'login',
                                              ),
                                              isLoading: isLoading,
                                              onPressed:
                                                  isLoading
                                                      ? null
                                                      : () =>
                                                          _handleLogin(context),
                                            )
                                            .animate(delay: 300.ms)
                                            .fadeIn(duration: 350.ms)
                                            .slideY(begin: 0.05, end: 0),
                                        const SizedBox(height: 20),
                                        const SocialLoginButtons(),
                                      ],
                                    ),
                                  )
                                  .animate(delay: 90.ms)
                                  .fadeIn(duration: 450.ms)
                                  .slideY(
                                    begin: 0.05,
                                    end: 0,
                                    curve: Curves.easeOutCubic,
                                  ),
                              const SizedBox(height: 22),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      L10n.translate(
                                        context,
                                        'dontHaveAccount',
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _RegisterLink(
                                      label: L10n.translate(
                                        context,
                                        'createAccount',
                                      ),
                                      onTap:
                                          () => context.go(
                                            AppStrings.routeRegistration,
                                          ),
                                    ),
                                  ],
                                ).animate(delay: 360.ms).fadeIn(duration: 400.ms),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOutCubic);
  }
}

class _LoginBackgroundDecor extends StatelessWidget {
  const _LoginBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          PositionedDirectional(
            top: -80,
            end: -60,
            child: _blurOrb(160, AppColors.primary.withValues(alpha: 0.05)),
          ),
          PositionedDirectional(
            top: 40,
            start: -70,
            child: _blurOrb(
              120,
              AppColors.primaryLight.withValues(alpha: 0.04),
            ),
          ),
          PositionedDirectional(
            top: 120,
            end: -30,
            child: _blurOrb(90, AppColors.accent.withValues(alpha: 0.03)),
          ),
        ],
      ),
    );
  }

  Widget _blurOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.height, required this.asset});

  final double height;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              width: height * 0.75,
              height: height * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                      asset,
                      height: height,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                      begin: 0,
                      end: -5,
                      duration: 2800.ms,
                      curve: Curves.easeInOut,
                    ),
              )
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

class _LoginGradientButton extends StatefulWidget {
  const _LoginGradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<_LoginGradientButton> createState() => _LoginGradientButtonState();
}

class _LoginGradientButtonState extends State<_LoginGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = true),
      onTapUp:
          widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = false),
      onTapCancel:
          widget.onPressed == null
              ? null
              : () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient:
                widget.onPressed == null
                    ? null
                : const LinearGradient(
                    colors: [Color(0xFFD98A9A), Color(0xFFC97C8A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
            color: widget.onPressed == null ? AppColors.textDisabled : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                widget.onPressed == null
                    ? null
                    : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
          ),
          child: Center(
            child:
                widget.isLoading
                    ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _RegisterLink extends StatefulWidget {
  const _RegisterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_RegisterLink> createState() => _RegisterLinkState();
}

class _RegisterLinkState extends State<_RegisterLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

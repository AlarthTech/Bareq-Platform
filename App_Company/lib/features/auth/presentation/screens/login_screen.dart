import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _heroAsset = 'assets/images/login_hero.png';

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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginEvent(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceBackground,
        body: Stack(
          children: [
            const _LoginBackgroundGlow(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = _LoginLayoutMetrics.fromConstraints(
                    context,
                    constraints.maxHeight,
                  );

                  return SingleChildScrollView(
                    physics: layout.fitsWithoutScroll
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: layout.topGap),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing20,
                          ),
                          child: _LoginHeroBanner(
                            assetPath: _heroAsset,
                            height: layout.heroHeight,
                          ),
                        ),
                        SizedBox(height: layout.heroToCardGap),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing20,
                          ),
                          child: _LoginFormCard(
                        formKey: _formKey,
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        usernameFocus: _usernameFocus,
                        passwordFocus: _passwordFocus,
                        obscurePassword: _obscurePassword,
                        rememberMe: _rememberMe,
                        onRememberChanged: (v) => setState(() => _rememberMe = v),
                        onTogglePassword: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        onLogin: _handleLogin,
                        onRegister: () => context.go(AppRoutes.register),
                        onForgotPassword: () => context.push(AppRoutes.forgotPassword),
                            compact: layout.isCompact,
                          ),
                        )
                            .animate(delay: 80.ms)
                            .fadeIn(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(
                              begin: 0.05,
                              end: 0,
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                            ),
                        SizedBox(height: layout.footerGap),
                        Text(
                          'Bareq Management v1.0.0',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.gray400,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                        )
                            .animate(delay: 280.ms)
                            .fadeIn(duration: AnimationConstants.fadeIn),
                        SizedBox(height: layout.bottomGap),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive login layout: hero height tiers + viewport cap so the form sits higher.
class _LoginLayoutMetrics {
  const _LoginLayoutMetrics({
    required this.heroHeight,
    required this.topGap,
    required this.heroToCardGap,
    required this.footerGap,
    required this.bottomGap,
    required this.fitsWithoutScroll,
    required this.isCompact,
  });

  final double heroHeight;
  final double topGap;
  final double heroToCardGap;
  final double footerGap;
  final double bottomGap;
  final bool fitsWithoutScroll;
  final bool isCompact;

  static const double _cardRadius = 28;
  static const double _estimatedFormHeight = 500;
  static const double _footerBlockHeight = 36;

  factory _LoginLayoutMetrics.fromConstraints(
    BuildContext context,
    double viewportHeight,
  ) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final shortestSide = media.size.shortestSide;

    final isCompact = screenHeight < 700 || shortestSide < 375;

    // Tiered hero height (logical px), not width-based aspect ratio.
    final double targetHero;
    if (screenHeight < 680 || shortestSide < 360) {
      targetHero = 220;
    } else if (screenHeight < 740 || shortestSide < 375) {
      targetHero = 232;
    } else if (screenHeight < 820) {
      targetHero = 258;
    } else if (screenHeight < 900) {
      targetHero = 268;
    } else {
      targetHero = 288;
    }

    final topGap = isCompact ? 6.0 : 10.0;
    final heroToCardGap = isCompact ? 10.0 : 14.0;
    final footerGap = isCompact ? 12.0 : 16.0;
    final bottomGap = isCompact ? 10.0 : 14.0;

    final reservedBelowHero = _estimatedFormHeight +
        topGap +
        heroToCardGap +
        footerGap +
        bottomGap +
        _footerBlockHeight;

    const minHeroHeight = 120.0;
    const maxHeroHeight = 300.0;
    final availableForHero = viewportHeight - reservedBelowHero;
    final maxHeroForViewport = math.min(
      maxHeroHeight,
      math.max(minHeroHeight, availableForHero),
    );
    final heroHeight = math.min(targetHero, maxHeroForViewport);

    final totalContentHeight =
        topGap + heroHeight + heroToCardGap + _estimatedFormHeight + footerGap + bottomGap + _footerBlockHeight;
    final fitsWithoutScroll = totalContentHeight <= viewportHeight + 4;

    return _LoginLayoutMetrics(
      heroHeight: heroHeight,
      topGap: topGap,
      heroToCardGap: heroToCardGap,
      footerGap: footerGap,
      bottomGap: bottomGap,
      fitsWithoutScroll: fitsWithoutScroll,
      isCompact: isCompact,
    );
  }
}

class _LoginHeroBanner extends StatelessWidget {
  const _LoginHeroBanner({
    required this.assetPath,
    required this.height,
  });

  final String assetPath;
  final double height;

  static const _radius = _LoginLayoutMetrics._cardRadius;
  /// Matches the warm off-white background sampled from [login_hero.png].
  static const _heroBackground = Color(0xFFFEFEFE);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _heroBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: _heroBackground.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: ColoredBox(
          color: _heroBackground,
          child: Center(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              width: double.infinity,
              height: height,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: _heroBackground,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 40,
                  color: AppTheme.gray400,
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: -0.04,
          end: 0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
  }
}

class _LoginBackgroundGlow extends StatelessWidget {
  const _LoginBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _glowBlob(220, AppTheme.primaryTeal.withValues(alpha: 0.07)),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _glowBlob(180, AppTheme.primaryTeal.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: 80,
            right: -30,
            child: _glowBlob(140, AppTheme.secondaryBlue.withValues(alpha: 0.04)),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    this.compact = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final bool compact;

  static const _cardRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final cardPadding = compact
        ? const EdgeInsets.fromLTRB(22, 22, 22, 20)
        : const EdgeInsets.fromLTRB(24, 26, 24, 22);
    final sectionGap = compact ? 22.0 : 26.0;
    final fieldGap = compact ? 14.0 : 18.0;

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppTheme.gray200.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تسجيل دخول الشركات',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gray900,
                    height: 1.25,
                  ),
            )
                .animate(delay: 120.ms)
                .fadeIn(duration: AnimationConstants.fadeIn),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'قم بإدارة العاملات والحجوزات بسهولة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray500,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
            )
                .animate(delay: 160.ms)
                .fadeIn(duration: AnimationConstants.fadeIn),
            SizedBox(height: sectionGap),
            _LoginField(
              label: 'اسم المستخدم / الهاتف',
              hint: 'أدخل رقم الهاتف أو اسم المستخدم',
              controller: usernameController,
              focusNode: usernameFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => passwordFocus.requestFocus(),
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المستخدم' : null,
              animationDelayMs: 200,
            ),
            SizedBox(height: fieldGap),
            _LoginField(
              label: 'كلمة المرور',
              hint: 'أدخل كلمة المرور',
              controller: passwordController,
              focusNode: passwordFocus,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.primaryTeal,
                  size: 22,
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'يرجى إدخال كلمة المرور' : null,
              animationDelayMs: 260,
            ),
            SizedBox(height: compact ? 10 : 14),
            Row(
              children: [
                SizedBox(
                  height: 28,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (v) => onRememberChanged(v ?? false),
                    activeColor: AppTheme.primaryTeal,
                    side: const BorderSide(color: AppTheme.gray300, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onRememberChanged(!rememberMe),
                    child: Text(
                      'تذكرني',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.gray700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ],
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: AnimationConstants.fadeIn),
            SizedBox(height: compact ? AppTheme.spacing20 : AppTheme.spacing24),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return _LoginGradientButton(
                  label: 'تسجيل الدخول',
                  icon: Icons.login_rounded,
                  isLoading: state is AuthLoading,
                  onPressed: state is AuthLoading ? null : onLogin,
                )
                    .animate(delay: 340.ms)
                    .fadeIn(duration: AnimationConstants.fadeIn)
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      end: const Offset(1, 1),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                    );
              },
            ),
            SizedBox(height: compact ? AppTheme.spacing16 : AppTheme.spacing20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ليس لديك حساب؟ ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                TextButton(
                  onPressed: onRegister,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryTeal,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'إنشاء حساب جديد',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            )
                .animate(delay: 380.ms)
                .fadeIn(duration: AnimationConstants.fadeIn),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    required this.validator,
    required this.animationDelayMs,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final FormFieldValidator<String> validator;
  final int animationDelayMs;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final Widget? suffixIcon;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.gray700,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray900,
                ),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFFCFCFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              prefixIcon: Icon(prefixIcon, color: AppTheme.primaryTeal, size: 22),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: AppTheme.gray200, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: AppTheme.gray200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: AppTheme.dangerRed, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: AppTheme.dangerRed, width: 1.5),
              ),
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray400,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ),
      ],
    )
        .animate(delay: animationDelayMs.ms)
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        )
        .slideX(
          begin: 0.03,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
  }
}

class _LoginGradientButton extends StatefulWidget {
  const _LoginGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<_LoginGradientButton> createState() => _LoginGradientButtonState();
}

class _LoginGradientButtonState extends State<_LoginGradientButton> {
  bool _pressed = false;

  static const _gradientStart = Color(0xFF0F9B8E);
  static const _gradientEnd = Color(0xFF0A7D73);

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: disabled ? 0.65 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gradientStart, _gradientEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _gradientEnd.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/forgot_password_colors.dart';

class ForgotPasswordGradientButton extends StatefulWidget {
  const ForgotPasswordGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<ForgotPasswordGradientButton> createState() =>
      _ForgotPasswordGradientButtonState();
}

class _ForgotPasswordGradientButtonState
    extends State<ForgotPasswordGradientButton> {
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
                        colors: [
                          ForgotPasswordColors.rose,
                          ForgotPasswordColors.pink,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
            color:
                widget.onPressed == null
                    ? ForgotPasswordColors.roseDark.withValues(alpha: 0.35)
                    : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                widget.onPressed == null
                    ? null
                    : [
                        BoxShadow(
                          color: ForgotPasswordColors.rose.withValues(alpha: 0.32),
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
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

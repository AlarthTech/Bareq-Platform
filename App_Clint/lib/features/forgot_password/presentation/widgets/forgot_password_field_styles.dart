import 'package:flutter/material.dart';
import '../theme/forgot_password_colors.dart';

/// Input decoration with rose/pink customer accents.
class ForgotPasswordFieldStyles {
  ForgotPasswordFieldStyles._();

  static const Color _borderNormal = Color(0xFFE5E7EB);
  static const Color _placeholderColor = Color(0xFF9CA3AF);

  static InputDecoration decoration(
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
            color: focused ? ForgotPasswordColors.rose : ForgotPasswordColors.roseDark,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ForgotPasswordColors.roseDark.withValues(alpha: 0.85),
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
                ? ForgotPasswordColors.rose
                : ForgotPasswordColors.pink.withValues(alpha: 0.75),
        size: 22,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: ForgotPasswordColors.roseLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _borderNormal, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: ForgotPasswordColors.pink.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ForgotPasswordColors.rose, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ForgotPasswordColors.rose),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ForgotPasswordColors.rose, width: 1.5),
      ),
    );
  }
}

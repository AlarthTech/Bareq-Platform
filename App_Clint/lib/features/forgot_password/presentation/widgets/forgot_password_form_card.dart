import 'package:flutter/material.dart';
import '../theme/forgot_password_colors.dart';

/// White rounded card with rose accent border.
class ForgotPasswordFormCard extends StatelessWidget {
  const ForgotPasswordFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: ForgotPasswordColors.pink.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: ForgotPasswordColors.rose.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

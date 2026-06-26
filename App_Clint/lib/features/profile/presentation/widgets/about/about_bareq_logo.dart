import 'package:flutter/material.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';

/// Bareq logo mark with optional premium glow — used in About screen & Hero.
class AboutBareqLogo extends StatelessWidget {
  const AboutBareqLogo({
    super.key,
    this.size = AboutScreenConstants.logoSize,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        AppAssets.bareqLogo,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!showGlow) {
      return logo;
    }

    return SizedBox(
      width: size + 48,
      height: size + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 36,
            height: size + 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  blurRadius: 56,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          logo,
        ],
      ),
    );
  }
}

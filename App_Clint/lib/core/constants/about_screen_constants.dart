import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Visual tokens for the premium About Bareq screen.
class AboutScreenConstants {
  AboutScreenConstants._();

  static const String logoHeroTag = 'bareq-about-logo';

  static const String facebookUrl = 'https://www.facebook.com/bareq.ly';
  static const String instagramUrl = 'https://www.instagram.com/bareq.ly';
  static const String xTwitterUrl = 'https://x.com/bareq.ly';

  static const double horizontalPadding = 24;
  static const double sectionSpacing = 28;
  static const double descriptionMaxWidth = 360;
  static const double logoSize = 96;
  static const double socialButtonSize = 52;
  static const double socialIconSize = 22;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFF8F0F2);
  static const Color textSubtle = Color(0xFFE8D4DA);
  static const Color socialButtonFill = Color(0x33FFFFFF);
  static const Color socialButtonBorder = Color(0x66FFFFFF);

  static const List<Color> logoGradient = [
    AppColors.primaryLight,
    AppColors.primary,
    AppColors.primaryDark,
  ];

  static const List<Color> backgroundGradient = [
    AppColors.primaryLight,
    AppColors.primary,
    AppColors.primaryDark,
  ];
}

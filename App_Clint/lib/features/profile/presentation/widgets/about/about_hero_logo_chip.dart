import 'package:flutter/material.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import 'about_bareq_logo.dart';

/// Compact logo wrapped in [Hero] for Profile → About transition.
class AboutHeroLogoChip extends StatelessWidget {
  const AboutHeroLogoChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: AboutScreenConstants.logoHeroTag,
      child: Material(
        color: Colors.transparent,
        child: AboutBareqLogo(size: 40, showGlow: false),
      ),
    );
  }
}

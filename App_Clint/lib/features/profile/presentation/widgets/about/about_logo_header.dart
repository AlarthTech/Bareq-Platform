import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import 'about_bareq_logo.dart';

class AboutLogoHeader extends StatelessWidget {
  const AboutLogoHeader({
    super.key,
    required this.appName,
    required this.versionLine,
    required this.buildLine,
    this.heroTag = AboutScreenConstants.logoHeroTag,
  });

  final String appName;
  final String versionLine;
  final String buildLine;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: heroTag,
          child: const Material(
            color: Colors.transparent,
            child: AboutBareqLogo(),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          appName,
          style: GoogleFonts.almarai(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AboutScreenConstants.textPrimary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          versionLine,
          style: GoogleFonts.almarai(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AboutScreenConstants.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          buildLine,
          style: GoogleFonts.almarai(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AboutScreenConstants.textSubtle,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/about_screen_constants.dart';

class AboutDescriptionSection extends StatelessWidget {
  const AboutDescriptionSection({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AboutScreenConstants.descriptionMaxWidth,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.almarai(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AboutScreenConstants.textMuted,
          height: 1.75,
        ),
      ),
    );
  }
}

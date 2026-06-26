import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import '../../../../../core/constants/app_colors.dart';

class AboutFooterLink extends StatefulWidget {
  const AboutFooterLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<AboutFooterLink> createState() => _AboutFooterLinkState();
}

class _AboutFooterLinkState extends State<AboutFooterLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        style: GoogleFonts.almarai(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color:
              _pressed
                  ? AboutScreenConstants.textPrimary
                  : AboutScreenConstants.textSubtle,
          decoration:
              _pressed ? TextDecoration.underline : TextDecoration.none,
          decorationColor: Colors.white,
          height: 1.6,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

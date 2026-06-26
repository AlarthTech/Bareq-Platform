import 'package:flutter/material.dart';
import '../../../../../core/constants/about_screen_constants.dart';

class AboutGradientBackground extends StatelessWidget {
  const AboutGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AboutScreenConstants.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}

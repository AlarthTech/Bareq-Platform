import 'package:flutter/material.dart';

/// Durations aligned with the reference app’s route transitions.
const Duration kFadePageTransitionDuration = Duration(milliseconds: 260);
const Duration kScaleFadePageTransitionDuration = Duration(milliseconds: 280);

/// Fade + subtle vertical slide — main app routes.
Widget fadePageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.024),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// Scale 0.95 → 1.0 + fade — used for login / registration (reference: scaleFade).
Widget scaleFadePageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
      child: child,
    ),
  );
}

/// Slide in from the end edge (visual “right” in LTR) with fade.
Widget slideFromRightPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final slide = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return SlideTransition(
    position: slide,
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

/// Slide in from the start edge (visual “left” in LTR) with fade.
Widget slideFromLeftPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final slide = Tween<Offset>(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return SlideTransition(
    position: slide,
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

/// Horizontal slide only (no fade).
Widget horizontalSlidePageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final slide = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return SlideTransition(position: slide, child: child);
}

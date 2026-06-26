import 'package:flutter/material.dart';

/// Shared motion values for [flutter_animate] chains (reference app style).
class AnimationConstants {
  AnimationConstants._();

  static const Duration fadeIn = Duration(milliseconds: 260);
  static const Curve fadeInCurve = Curves.easeOutCubic;

  /// Buttons, nav taps — fast feedback.
  static const Duration microInteraction = Duration(milliseconds: 220);

  /// Stagger between list rows / form groups.
  static const int staggerMs = 40;

  /// Header slideY (home-style greeting).
  static const double headerSlideYBegin = -0.03;
}

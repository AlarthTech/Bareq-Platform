import 'package:flutter/material.dart';

/// App color constants - Modern Soft Feminine palette
/// Designed for calm, warm, clean, and trustworthy experience
class AppColors {
  AppColors._();

  // Primary Brand Colors - Dusty Rose
  static const Color primary = Color(0xFFC97C8A); // Dusty Rose
  static const Color primaryLight = Color(0xFFE3B4BD);
  static const Color primaryDark = Color(0xFFB05D6E);

  // Secondary Colors - Light Sand
  static const Color secondary = Color(0xFFFAF6F2); // Light Sand
  static const Color secondaryLight = Color(0xFFFFFCF9);
  static const Color secondaryDark = Color(0xFFE8E0D8);
  
  // Gradient Colors for Backgrounds
  static const Color gradientTop = Color(0xFFFFF7F5); // Soft warm white for greeting section
  static const Color gradientBottom = Color(0xFFFFFFFF); // Pure white
  static const Color gradientHaloCenter = Color(0xFFFFF7F5); // Radial gradient center for avatar
  static const Color gradientHaloEdge = Color(0xFFF1E8F5); // Radial gradient edge (lavender tint)

  // Accent Colors - Lavender
  static const Color accent = Color(0xFFA88BEB); // Lavender
  static const Color accentLight = Color(0xFFC4B2F0);
  static const Color accentDark = Color(0xFF8B6DD4);

  // Status Colors
  static const Color success = Color(0xFF7BC67B); // Soft Green
  static const Color error = Color(0xFFE57373); // Soft Red
  static const Color warning = Color(0xFFFFB74D); // Soft Orange
  static const Color info = Color(0xFF81D4FA); // Soft Blue

  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF); // Off-White / Pure White
  static const Color surface = Color(0xFFFFFFFF); // Pure White (Cards)
  static const Color surfaceVariant = Color(0xFFFAF6F2); // Light Sand

  // Text Colors
  static const Color textPrimary = Color(0xFF2E2E2E); // Deep Charcoal
  static const Color textSecondary = Color(0xFF7A7A7A); // Muted Gray
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Border & Divider
  static const Color border = Color(0xFFE8E0D8); // Soft border
  static const Color divider = Color(0xFFF5F0EB); // Very light divider

  // Dark Theme Colors (for future dark mode support)
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2C2C2C);
  static const Color darkSurfaceVariant = Color(0xFF3A3A3A);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
}


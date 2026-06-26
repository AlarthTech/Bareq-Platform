import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Dark theme configuration following Material 3 design
class DarkTheme {
  static ThemeData get theme {
    // Create base theme with Material 3 defaults
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
    );
    
    // Apply Google Fonts Almarai to the base theme's textTheme
    // This ensures Material 3 compatibility
    final textTheme = GoogleFonts.almaraiTextTheme(baseTheme.textTheme);
    
    // Build final theme with Google Fonts applied
    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.almarai(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: textTheme.copyWith(
        // Display (Screen titles, major headings) - SemiBold
        displayLarge: textTheme.displayLarge?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600, // SemiBold
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600, // SemiBold
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600, // SemiBold
        ),
        // Headline (Section headers) - Medium
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500, // Medium
        ),
        // Title (Names, card titles) - SemiBold
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500, // Medium (for section headers)
        ),
        // Body (Descriptions, labels) - Regular
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400, // Regular
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.darkTextSecondary.withOpacity(0.8), // Meta - Regular + opacity
          fontSize: 12,
          fontWeight: FontWeight.w400, // Regular
        ),
      ),
      primaryTextTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
    );
  }
}


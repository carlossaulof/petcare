import 'package:flutter/material.dart';

/// Paleta PetCare: verde-sálvia, branco, bege e creme.
class AppColors {
  static const sage = Color(0xFF5E7D63);
  static const sageDark = Color(0xFF3F5A45);
  static const sageLight = Color(0xFFDDE8DC);
  static const sageSoft = Color(0xFFE8F0E6);
  static const cream = Color(0xFFF6F1E9);
  static const beige = Color(0xFFE9DFCF);
  static const beigeDark = Color(0xFFC9B89C);
  static const white = Colors.white;
  static const ink = Color(0xFF2E3A30);
  static const muted = Color(0xFF7A847B);
  static const danger = Color(0xFFC0473F);
  static const warning = Color(0xFFD49A3A);
  static const lilac = Color(0xFFE6DCEB);
  static const info = Color(0xFF4F7A95);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      primary: AppColors.sage,
      secondary: AppColors.beigeDark,
      surface: AppColors.white,
      error: AppColors.danger,
      brightness: Brightness.light,
    );
    final radius = BorderRadius.circular(16);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.sageDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.sageDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.ink),
        bodyMedium: TextStyle(color: AppColors.ink),
        bodySmall: TextStyle(color: AppColors.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F0EC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.sage,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageDark,
          minimumSize: const Size(64, 50),
          side: const BorderSide(color: AppColors.sage),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.sageLight,
        side: const BorderSide(color: AppColors.beige),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.sageLight,
        height: 68,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, color: AppColors.ink),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

import 'package:flutter/material.dart';

/// Central place for colors and the app theme so the whole app looks consistent.
class AppColors {
  static const primary = Color(0xFF1565C0); // school blue
  static const accent = Color(0xFFFFA726); // amber
  static const lost = Color(0xFFD84315); // deep orange  -> LOST items
  static const found = Color(0xFF2E7D32); // green        -> FOUND items
  static const background = Color(0xFFF5F8FD);
  static const textDark = Color(0xFF1B2433);
  static const textMuted = Color(0xFF5F6B7A);
  static const lostSoft = Color(0xFFFBE9E3);
  static const foundSoft = Color(0xFFE4F2E5);
  static const primarySoft = Color(0xFFE3EEFC);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      brightness: Brightness.light,
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(const Color(0xFFCBD5E1)),
        enabledBorder: border(const Color(0xFFCBD5E1)),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(Colors.red.shade700),
        focusedErrorBorder: border(Colors.red.shade700, 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52), // big touch target
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

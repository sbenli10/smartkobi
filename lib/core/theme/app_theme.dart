import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
    );

    final scheme = const ColorScheme.dark(
      primary: AppColors.gold500,
      secondary: AppColors.gold400,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: AppColors.navy900,
      onSecondary: AppColors.navy900,
      onSurface: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navy900,
      canvasColor: AppColors.navy900,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      cardColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: _textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: _textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.gold500, width: 1.2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.gold500,
          foregroundColor: AppColors.navy900,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold500,
        foregroundColor: AppColors.navy900,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppColors.gold500),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: _textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: _textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold500,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w800,
    ),
    titleLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w800,
    ),
    titleMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

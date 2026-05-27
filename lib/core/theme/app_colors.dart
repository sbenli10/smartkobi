import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primaryNavy = Color(0xFF0B1F3A);
  static const Color primaryNavySoft = Color(0xFFE8F5F7);
  static const Color turquoise = Color(0xFF18B8BD);
  static const Color turquoiseSoft = Color(0xFFE4F8F9);
  static const Color accentGold = Color(0xFFC89B3C);
  static const Color accentGoldSoft = Color(0xFFFFF7E6);

  static const Color background = Color(0xFFF4FAFB);
  static const Color scaffoldBackground = background;
  static const Color scaffold = background;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF8FA);
  static const Color border = Color(0xFFDDECEF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Backward compatibility aliases for older screens.
  static const Color navy950 = primaryNavy;
  static const Color navy900 = surfaceAlt;
  static const Color navy800 = surfaceAlt;
  static const Color navy700 = primaryNavySoft;
  static const Color gold500 = accentGold;
  static const Color gold400 = accentGold;
}

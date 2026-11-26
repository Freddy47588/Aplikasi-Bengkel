import 'package:flutter/material.dart';

/// Shared Crisp Automotive color palette for BengkelKu.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF111827);
  static const Color carbonElevated = Color(0xFF181D27);
  static const Color splashBg = Color(0xFF050B0B);

  static const Color secondary = Color(0xFFEA580C);
  static const Color accent = Color(0xFFEA580C);
  static const Color accentLight = Color(0xFFFB923C);
  static const Color accentSoft = Color(0xFFFFF3EC);
  static const Color accentBorder = Color(0xFFFED7AA);

  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color controlBorder = Color(0xFFD1D5DB);
  static const Color muted = Color(0xFF6B7280);
  static const Color onMuted = Color(0xFF4B5563);

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF1D4ED8);

  // Compatibility aliases kept during gradual screen migration.
  static const Color blueSurface = accentSoft;
  static const Color blueBorder = accentBorder;
}

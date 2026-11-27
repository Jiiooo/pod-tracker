import 'package:flutter/material.dart';

/// Palet warna aplikasi (dark / light). Satu aksen: cyan.
class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
  });

  Color get accentSoft => accent.withValues(alpha: 0.12);

  static const dark = AppColors(
    background: Color(0xFF0B0D10),
    surface: Color(0xFF14171C),
    surfaceRaised: Color(0xFF1B1F26),
    outline: Color(0xFF262B33),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFF9AA3AF),
    accent: Color(0xFF22D3EE),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  static const light = AppColors(
    background: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0F2F5),
    outline: Color(0xFFE3E6EB),
    textPrimary: Color(0xFF0F1217),
    textSecondary: Color(0xFF5B6472),
    accent: Color(0xFF0891B2),
    success: Color(0xFF059669),
    warning: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
  );
}

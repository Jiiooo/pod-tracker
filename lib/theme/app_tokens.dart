import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Warna semantik yang tidak ada di ColorScheme.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color success;
  final Color warning;
  final Color textSecondary;
  final Color surfaceRaised;
  final Color outline;
  final Color accentSoft;
  final Color danger;
  final bool isDark;

  const AppTokens({
    required this.success,
    required this.warning,
    required this.textSecondary,
    required this.surfaceRaised,
    required this.outline,
    required this.accentSoft,
    required this.danger,
    required this.isDark,
  });

  factory AppTokens.from(AppColors c, {required bool isDark}) => AppTokens(
        success: c.success,
        warning: c.warning,
        textSecondary: c.textSecondary,
        surfaceRaised: c.surfaceRaised,
        outline: c.outline,
        accentSoft: c.accentSoft,
        danger: c.danger,
        isDark: isDark,
      );

  /// Bayangan lembut hanya di light mode; dark mode memakai hairline.
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ];

  /// Angka tabular agar digit rata (watt, ohm, harga).
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  @override
  AppTokens copyWith({
    Color? success,
    Color? warning,
    Color? textSecondary,
    Color? surfaceRaised,
    Color? outline,
    Color? accentSoft,
    Color? danger,
    bool? isDark,
  }) =>
      AppTokens(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        textSecondary: textSecondary ?? this.textSecondary,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        outline: outline ?? this.outline,
        accentSoft: accentSoft ?? this.accentSoft,
        danger: danger ?? this.danger,
        isDark: isDark ?? this.isDark,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppThemeX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_tokens.dart';

const String kFontFamily = 'PlusJakartaSans';

class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static TextStyle _s(double size, FontWeight w, Color color,
          {double? height, double? letterSpacing}) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme _textTheme(AppColors c) => TextTheme(
        displayLarge: _s(32, FontWeight.w800, c.textPrimary, letterSpacing: -0.5),
        displayMedium: _s(32, FontWeight.w800, c.textPrimary, letterSpacing: -0.5),
        displaySmall: _s(28, FontWeight.w800, c.textPrimary, letterSpacing: -0.4),
        headlineLarge: _s(22, FontWeight.w700, c.textPrimary),
        headlineMedium: _s(22, FontWeight.w700, c.textPrimary),
        headlineSmall: _s(18, FontWeight.w700, c.textPrimary),
        titleLarge: _s(22, FontWeight.w700, c.textPrimary, letterSpacing: -0.3),
        titleMedium: _s(18, FontWeight.w700, c.textPrimary),
        titleSmall: _s(15, FontWeight.w600, c.textPrimary),
        bodyLarge: _s(15, FontWeight.w400, c.textPrimary, height: 1.45),
        bodyMedium: _s(15, FontWeight.w400, c.textPrimary, height: 1.45),
        bodySmall: _s(12, FontWeight.w500, c.textSecondary),
        labelLarge: _s(13, FontWeight.w600, c.textPrimary),
        labelMedium: _s(13, FontWeight.w600, c.textPrimary),
        labelSmall: _s(12, FontWeight.w500, c.textSecondary),
      );

  static ThemeData _build(AppColors c, Brightness b) {
    final isDark = b == Brightness.dark;
    final tt = _textTheme(c);
    final scheme = ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: isDark ? const Color(0xFF04222A) : const Color(0xFFFFFFFF),
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
      secondary: c.accent,
      onSecondary: isDark ? const Color(0xFF04222A) : const Color(0xFFFFFFFF),
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.accent,
      tertiary: c.accent,
      onTertiary: isDark ? const Color(0xFF04222A) : const Color(0xFFFFFFFF),
      error: c.danger,
      onError: isDark ? const Color(0xFF2A0A0A) : const Color(0xFFFFFFFF),
      errorContainer: c.danger.withValues(alpha: 0.12),
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.outline,
      outlineVariant: c.outline,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      inversePrimary: c.accent,
      surfaceTint: const Color(0x00000000),
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: Rd.fieldR,
      borderSide: BorderSide.none,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: Rd.fieldR);
    const buttonSize = Size.fromHeight(52);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: kFontFamily,
      textTheme: tt,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.outline,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [AppTokens.from(c, isDark: isDark)],
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: Sp.l,
        titleTextStyle: tt.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Rd.cardR,
          side: BorderSide(color: c.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.l),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: Rd.fieldR,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Rd.fieldR,
          borderSide: BorderSide(color: c.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Rd.fieldR,
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
        labelStyle: _s(15, FontWeight.w400, c.textSecondary),
        floatingLabelStyle: _s(13, FontWeight.w600, c.accent),
        hintStyle: _s(15, FontWeight.w400, c.textSecondary),
        helperStyle: tt.bodySmall,
        errorStyle: _s(12, FontWeight.w500, c.danger),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          backgroundColor: c.accent,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: c.surfaceRaised,
          disabledForegroundColor: c.textSecondary,
          textStyle: _s(15, FontWeight.w700, scheme.onPrimary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          elevation: 0,
          backgroundColor: c.accent,
          foregroundColor: scheme.onPrimary,
          textStyle: _s(15, FontWeight.w700, scheme.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.outline),
          textStyle: _s(15, FontWeight.w600, c.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: buttonShape,
          foregroundColor: c.accent,
          textStyle: _s(15, FontWeight.w600, c.accent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: c.textPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceRaised,
        selectedColor: c.accentSoft,
        disabledColor: c.surfaceRaised,
        side: BorderSide(color: c.outline),
        shape: RoundedRectangleBorder(borderRadius: Rd.chipR),
        labelStyle: _s(13, FontWeight.w600, c.textPrimary),
        secondaryLabelStyle: _s(13, FontWeight.w600, c.accent),
        checkmarkColor: c.accent,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: Sp.s, vertical: Sp.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accentSoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? c.accent : c.textSecondary,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => _s(
              12,
              s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              s.contains(WidgetState.selected) ? c.accent : c.textSecondary,
            )),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: scheme.onPrimary,
        elevation: isDark ? 0 : 2,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.outline,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(Rd.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rd.dialog),
          side: BorderSide(color: c.outline),
        ),
        titleTextStyle: tt.titleMedium,
        contentTextStyle: _s(15, FontWeight.w400, c.textSecondary, height: 1.45),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: _s(14, FontWeight.w500, c.background),
        actionTextColor: c.accent,
        shape: RoundedRectangleBorder(borderRadius: Rd.fieldR),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: _s(15, FontWeight.w600, c.textPrimary),
        subtitleTextStyle: _s(13, FontWeight.w400, c.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l),
        minVerticalPadding: Sp.s,
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.onPrimary : c.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.accent : c.surfaceRaised),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.accent : c.outline),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.surfaceRaised,
        thumbColor: c.accent,
        overlayColor: c.accentSoft,
        valueIndicatorColor: c.accent,
        valueIndicatorTextStyle: _s(13, FontWeight.w700, scheme.onPrimary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: Rd.fieldR)),
          side: WidgetStatePropertyAll(BorderSide(color: c.outline)),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? c.accentSoft : c.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? c.accent : c.textSecondary),
          textStyle: WidgetStatePropertyAll(_s(13, FontWeight.w600, c.textPrimary)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionHandleColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.3),
      ),
    );
  }
}

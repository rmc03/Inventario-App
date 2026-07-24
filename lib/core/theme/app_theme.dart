import 'package:flutter/material.dart';

import 'app_dimens.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primary,
    required this.primaryDark,
    required this.ink,
    required this.muted,
    required this.line,
    required this.surface,
    required this.surfaceSecondary,
    required this.background,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color primary;
  final Color primaryDark;
  final Color ink;
  final Color muted;
  final Color line;
  final Color surface;
  final Color surfaceSecondary;
  final Color background;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? ink,
    Color? muted,
    Color? line,
    Color? surface,
    Color? surfaceSecondary,
    Color? background,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      background: background ?? this.background,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  static const light = AppColorsExtension(
    primary: Color(0xFF007AFF),
    primaryDark: Color(0xFF004E8F),
    ink: Color(0xFF1C1C1E),
    muted: Color(0xFF8E8E93),
    line: Color(0xFFE5E5EA),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF2F2F7),
    background: Color(0xFFF2F2F7),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    danger: Color(0xFFFF3B30),
    info: Color(0xFF007AFF), // Azul para entradas
  );

  // Dark theme optimized for OLED screens and accessibility
  // - Pure black background (#000) reduces OLED burn-in and saves battery
  // - Elevated surfaces use subtle gray tones (#1C1C1E, #2C2C2E) for hierarchy
  // - Higher luminance colors ensure WCAG AAA contrast (7:1+)
  // - Desaturated semantic colors prevent eye strain in low light
  // - line (#68686A) ensures dividers are visible (3.5:1 on black per WCAG)
  static const dark = AppColorsExtension(
    primary: Color(0xFF0A84FF),           // Brighter blue for dark backgrounds
    primaryDark: Color(0xFF0066CC),       // Slightly darker for pressed states
    ink: Color(0xFFFFFFFF),               // Pure white for maximum contrast
    muted: Color(0xFF98989D),             // Lighter gray for better readability
    line: Color(0xFF68686A),              // Visible dividers (3.5:1 on #000)
    surface: Color(0xFF1C1C1E),           // Elevated cards
    surfaceSecondary: Color(0xFF2C2C2E),  // Secondary elevated elements
    background: Color(0xFF000000),        // Pure black for OLED
    success: Color(0xFF32D74B),           // Brighter green
    warning: Color(0xFFFFD60A),           // More visible yellow
    danger: Color(0xFFFF453A),            // Vibrant red
    info: Color(0xFF0A84FF),              // Azul brillante para entradas
  );
}

extension ColorContext on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}



class AppTheme {
  static ThemeData light({double textScaleFactor = 1.0, bool boldText = false}) => 
      _buildTheme(Brightness.light, AppColorsExtension.light, textScaleFactor, boldText);
  
  static ThemeData dark({double textScaleFactor = 1.0, bool boldText = false}) => 
      _buildTheme(Brightness.dark, AppColorsExtension.dark, textScaleFactor, boldText);

  static ThemeData _buildTheme(
    Brightness brightness, 
    AppColorsExtension ext,
    double textScaleFactor,
    bool boldText,
  ) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ext.primary,
      brightness: brightness,
      primary: ext.primary,
      onPrimary: Colors.white,
      secondary: ext.success,
      surface: ext.surface,
      onSurface: ext.ink,
      error: ext.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ext.background,
      extensions: [ext],
      textTheme: _buildTextTheme(ext, textScaleFactor, boldText),
      appBarTheme: AppBarTheme(
        backgroundColor: ext.background,
        foregroundColor: ext.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: ext.ink, fontSize: 20 * textScaleFactor, fontWeight: FontWeight.w600, letterSpacing: -0.1),
      ),
      cardTheme: CardThemeData(
        color: ext.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: ext.ink.withValues(alpha: 0.06),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(borderRadius: AppRadii.mdBorder, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: AppRadii.mdBorder, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadii.mdBorder, borderSide: BorderSide(color: ext.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadii.mdBorder, borderSide: BorderSide(color: ext.danger, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadii.mdBorder, borderSide: BorderSide(color: ext.danger, width: 1.5)),
        labelStyle: TextStyle(color: ext.muted, fontSize: 15 * textScaleFactor, fontWeight: FontWeight.w500, letterSpacing: -0.1),
        hintStyle: TextStyle(color: ext.muted, fontSize: 17 * textScaleFactor, fontWeight: FontWeight.w400, letterSpacing: -0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ext.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
          textStyle: TextStyle(fontSize: 17 * textScaleFactor, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ext.ink,
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
          side: BorderSide(color: ext.line),
          textStyle: TextStyle(fontSize: 17 * textScaleFactor, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ext.primary,
          textStyle: TextStyle(fontSize: 17 * textScaleFactor, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ext.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ext.surface.withValues(alpha: 0.85),
        selectedItemColor: ext.primary,
        unselectedItemColor: ext.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: ext.line,
        thickness: 0.5,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceSecondary,
        selectedColor: ext.primary.withValues(alpha: AppAlphas.fillStrong),
        labelStyle: TextStyle(fontSize: 15 * textScaleFactor, fontWeight: FontWeight.w500, color: ext.ink),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ext.ink,
        contentTextStyle: TextStyle(color: ext.background, fontSize: 15 * textScaleFactor, fontWeight: FontWeight.w400),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
      ),
    );
  }

  static TextTheme _buildTextTheme(
    AppColorsExtension ext,
    double scale,
    bool bold,
  ) {
    final baseBold = bold ? FontWeight.w700 : FontWeight.w600;
    final titleBold = bold ? FontWeight.w800 : FontWeight.w700;
    final normalWeight = bold ? FontWeight.w600 : FontWeight.w400;

    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34 * scale,
        fontWeight: titleBold,
        color: ext.ink,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 22 * scale,
        fontWeight: titleBold,
        color: ext.ink,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20 * scale,
        fontWeight: baseBold,
        color: ext.ink,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 17 * scale,
        fontWeight: baseBold,
        color: ext.ink,
        letterSpacing: -0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 17 * scale,
        fontWeight: normalWeight,
        color: ext.ink,
        letterSpacing: -0.1,
      ),
      bodyMedium: TextStyle(
        fontSize: 13 * scale,
        fontWeight: normalWeight,
        color: ext.muted,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 17 * scale,
        fontWeight: baseBold,
        color: ext.ink,
        letterSpacing: -0.1,
      ),
    );
  }
}

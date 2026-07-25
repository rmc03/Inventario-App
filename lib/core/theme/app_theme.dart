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

  // Light mode: Indigo navy + copper accent — premium, authoritative, memorable
  // The copper (info) acts as a warm counterpoint to the cool indigo,
  // echoing classic motorcycle-brand color tension (Triumph, Ducati).
  static const light = AppColorsExtension(
    primary: Color(0xFF1A237E),           // Deep indigo navy
    primaryDark: Color(0xFF0D1453),       // Pressed state
    ink: Color(0xFF1C1C1E),
    muted: Color(0xFF6B7280),             // Slate gray
    line: Color(0xFFD1D5DB),              // Light border
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFEEF0F7),  // Hint of indigo
    background: Color(0xFFF5F6FA),        // Cool off-white
    success: Color(0xFF2E7D32),
    warning: Color(0xFFE65100),
    danger: Color(0xFFC62828),
    info: Color(0xFFC75B39),              // Warm copper — the personality accent
  );

  // Dark mode: Navy-toned surfaces (never pure black) + brighter copper accent
  // The navy undertone gives personality without compromising OLED friendliness.
  static const dark = AppColorsExtension(
    primary: Color(0xFF5C6BC0),           // Indigo 400 — legible on dark
    primaryDark: Color(0xFF3949AB),       // Pressed state
    ink: Color(0xFFF5F5F5),
    muted: Color(0xFF9E9E9E),
    line: Color(0xFF424242),
    surface: Color(0xFF1A1C2E),           // Navy-undertone surface
    surfaceSecondary: Color(0xFF252740),  // Slightly lighter navy
    background: Color(0xFF0F1120),       // Deep navy scaffold
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFA726),
    danger: Color(0xFFEF5350),
    info: Color(0xFFE87A5A),              // Brighter copper for dark
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
      secondary: ext.info,
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

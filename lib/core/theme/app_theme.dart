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

  // Light mode: Azure blue + copper accent — fresh, professional, memorable
  // Azure blue is vibrant yet trustworthy, perfect for retail operations.
  // Copper (info) creates warm moments against the cool blue foundation.
  // Delight thesis: "Warmth in reliability" — copper signals success, completion, and human moments.
  static const light = AppColorsExtension(
    primary: Color(0xFF0F62FE),           // Azure blue — vibrant, modern, trustworthy
    primaryDark: Color(0xFF0043CE),       // Pressed state (deeper blue)
    ink: Color(0xFF161616),               // Near-black text (softer than pure black)
    muted: Color(0xFF6F6F6F),             // Warm gray (secondary content)
    line: Color(0xFFE0E0E0),              // Light border
    surface: Color(0xFFFFFFFF),           // Card surface (white)
    surfaceSecondary: Color(0xFFF0F2F5),  // Neutral gray-blue (subtle)
    background: Color(0xFFF5F5F5),        // Neutral gray scaffold (más gris)
    success: Color(0xFF24A148),           // Fresh green (operational success)
    warning: Color(0xFFB95000),           // Deep amber (caution, legible on white)
    danger: Color(0xFFDA1E28),            // Vibrant red (errors, stock alerts)
    info: Color(0xFFE8743B),              // 🔥 Warm copper — PERSONALITY ACCENT
                                          // Use for: sale completions, sync success, daily close,
                                          // inventory additions, positive milestones, unit counts
  );

  // Dark mode: Clean minimal — WhatsApp-inspired gray + blue accent
  // Clean neutral dark gray matching WhatsApp's aesthetic
  // Blue hero accent appears strategically (AppBar, key moments)
  // Delight thesis: "Clean focus" — minimal, clear, functional
  static const dark = AppColorsExtension(
    primary: Color(0xFF5B9FFF),           // Electric azure — vibrant hero accent
    primaryDark: Color(0xFF85B8FF),       // Pressed state (brighter for feedback)
    ink: Color(0xFFE5E5E5),               // Soft white text (easy on eyes)
    muted: Color(0xFF999999),             // Medium gray for secondary content
    line: Color(0xFF2A2A2A),              // Subtle dark border
    surface: Color(0xFF1F1F1F),           // Card surface (slightly lighter than background)
    surfaceSecondary: Color(0xFF2A2A2A),  // Slightly lighter gray
    background: Color(0xFF111111),        // 🔥 WhatsApp-style background (very similar to #0E0E0E)
    success: Color(0xFF3FD372),           // Neon green — vibrant success moments
    warning: Color(0xFFFFD23F),           // Bright amber — high visibility warnings
    danger: Color(0xFFFF6B7A),            // Hot pink-red — urgent alerts
    info: Color(0xFFFF8B5A),              // Vibrant copper — warm personality accent
  );
}

extension ColorContext on BuildContext {
  AppColorsExtension get colors {
    final extension = Theme.of(this).extension<AppColorsExtension>();
    if (extension != null) return extension;
    
    // Fallback: retornar colores por defecto basados en brightness
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? AppColorsExtension.dark 
        : AppColorsExtension.light;
  }
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
      surfaceTint: Colors.transparent,  // 🔥 Evita el tint azul claro en transiciones
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ext.background,
      extensions: [ext],
      textTheme: _buildTextTheme(ext, textScaleFactor, boldText),
      appBarTheme: AppBarTheme(
        // 🔥 En light mode: fondo azul vibrante con texto blanco
        // En dark mode: fondo oscuro limpio como WhatsApp
        backgroundColor: brightness == Brightness.light ? ext.primary : ext.background,
        foregroundColor: brightness == Brightness.light ? Colors.white : ext.ink,
        surfaceTintColor: Colors.transparent,  // 🔥 Evita el tint azul claro en transiciones
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: brightness == Brightness.light ? Colors.white : ext.ink,
          fontSize: 20 * textScaleFactor,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        iconTheme: IconThemeData(
          color: brightness == Brightness.light ? Colors.white : ext.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: ext.surface,
        elevation: 0,  // Sin elevación en dark mode tampoco
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
        elevation: 4,  // Elevación estándar en ambos modos
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

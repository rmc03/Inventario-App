import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'app_color_schemes.dart';
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

  // 💳 LIGHT MODE: Cash App Style — Minimalista Premium
  // Inspiración: Cash App, Mercury, Brex
  // Neutros suaves + azul índigo como acento estratégico
  // Tipografía bold, radii grandes, espaciado generoso
  static const light = AppColorsExtension(
    primary: Color(0xFF4F46E5),           // 💼 Índigo 600 — acento estratégico (no dominante)
    primaryDark: Color(0xFF4338CA),       // Índigo 700 (pressed)
    ink: Color(0xFF1A1A1A),               // Negro suave (no puro) — títulos pesados
    muted: Color(0xFF6B7280),             // Gray 500 — texto secundario
    line: Color(0xFFE5E7EB),              // Gray 200 — bordes sutiles
    surface: Color(0xFFFFFFFF),           // Blanco puro (cards destacadas)
    surfaceSecondary: Color(0xFFF3F4F6),  // Gray 100 — botones pill, fondos secundarios
    background: Color(0xFFFAFAFA),        // 🎨 Gris ultra claro — scaffold limpio (Cash App style)
    success: Color(0xFF10B981),           // Emerald 500 — éxito
    warning: Color(0xFFF59E0B),           // Amber 500 — advertencias
    danger: Color(0xFFEF4444),            // Red 500 — errores
    info: Color(0xFF8B5CF6),              // 🔮 Violet 500 — ilustraciones, momentos especiales
  );

  // 🌙 DARK MODE: Premium Dark
  // Slate oscuro profesional + índigo vibrante
  static const dark = AppColorsExtension(
    primary: Color(0xFF818CF8),           // 💼 Índigo 400 — vibrante
    primaryDark: Color(0xFFA5B4FC),       // Índigo 300 (pressed)
    ink: Color(0xFFFAFAFA),               // Blanco suave — títulos
    muted: Color(0xFF9CA3AF),             // Gray 400 — secundario
    line: Color(0xFF374151),              // Gray 700 — bordes
    surface: Color(0xFF1F2937),           // Gray 800 — cards
    surfaceSecondary: Color(0xFF111827),  // Gray 900 — fondos secundarios
    background: Color(0xFF0F172A),        // Slate 900 — base oscura
    success: Color(0xFF34D399),           // Emerald 400
    warning: Color(0xFFFBBF24),           // Amber 400
    danger: Color(0xFFF87171),            // Red 400
    info: Color(0xFFA78BFA),              // 🔮 Violet 400
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
  static ThemeData light({
    double textScaleFactor = 1.0,
    bool boldText = false,
    bool reduceAnimations = false,
    AppColorScheme? colorScheme,
  }) {
    final ext = colorScheme != null ? colorScheme.light : AppColorsExtension.light;
    return _buildTheme(Brightness.light, ext, textScaleFactor, boldText, reduceAnimations);
  }

  static ThemeData dark({
    double textScaleFactor = 1.0,
    bool boldText = false,
    bool reduceAnimations = false,
    AppColorScheme? colorScheme,
  }) {
    final ext = colorScheme != null ? colorScheme.dark : AppColorsExtension.dark;
    return _buildTheme(Brightness.dark, ext, textScaleFactor, boldText, reduceAnimations);
  }

static ThemeData _buildTheme(
    Brightness brightness, 
    AppColorsExtension ext,
    double textScaleFactor,
    bool boldText,
    bool reduceAnimations,
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
      pageTransitionsTheme: reduceAnimations
          ? const PageTransitionsTheme(builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            })
          : null,
      appBarTheme: AppBarTheme(
        // 💳 CASH APP STYLE: Fondo casi blanco, título NEGRO bold y grande
        // Sin colores en el título — minimalista y limpio
        backgroundColor: brightness == Brightness.light 
            ? ext.background      // Gris ultra claro (como Cash App)
            : ext.background,     // Oscuro en dark mode
        foregroundColor: ext.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,  // Sin sombra — flat como Cash App
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          color: ext.ink,  // 🎨 NEGRO en light, blanco en dark (no color primario)
          fontSize: 32 * textScaleFactor,  // MÁS GRANDE — Cash App style
          fontWeight: FontWeight.w900,     // BLACK weight — máximo peso
          letterSpacing: -1.0,             // Tight tracking
          height: 1.0,
        ),
        iconTheme: IconThemeData(
          color: ext.ink,
          size: 28,  // Íconos más grandes
        ),
        actionsIconTheme: IconThemeData(
          color: ext.ink,
          size: 28,
        ),
      ),
      cardTheme: CardThemeData(
        color: ext.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,  // Sin sombra — flat como Cash App
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgBorder,  // 20px — radii grande Cash App style
          side: brightness == Brightness.dark
              ? BorderSide(
                  color: ext.line,
                  width: 0.5,
                )
              : BorderSide.none,
        ),
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
        labelStyle: TextStyle(fontFamily: AppFonts.family,color: ext.muted, fontSize: 15 * textScaleFactor, fontWeight: FontWeight.w500, letterSpacing: -0.1),
        hintStyle: TextStyle(fontFamily: AppFonts.family,color: ext.muted, fontSize: 17 * textScaleFactor, fontWeight: FontWeight.w400, letterSpacing: -0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ext.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),  // Más alto — Cash App style
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgBorder),  // 20px radius
          textStyle: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 17 * textScaleFactor,
            fontWeight: FontWeight.w700,  // Bold
            letterSpacing: -0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // 💳 CASH APP STYLE: Botones pill con fondo gris claro (no outlined)
          backgroundColor: ext.surfaceSecondary,  // Fondo gris claro
          foregroundColor: ext.ink,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillBorder),  // Pill shape
          side: BorderSide.none,  // Sin border — solo fondo
          textStyle: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 16 * textScaleFactor,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ext.primary,
          textStyle: TextStyle(fontFamily: AppFonts.family,fontSize: 17 * textScaleFactor, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ext.primary,
        foregroundColor: Colors.white,
        elevation: 4,  // Elevación estándar en ambos modos
        shape: const CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? ext.surface.withValues(alpha: 0.95)
            : ext.surface.withValues(alpha: 0.95),
        selectedItemColor: ext.primary,
        unselectedItemColor: ext.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w700,  // Bold cuando está seleccionado
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ext.line,
        thickness: 0.5,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceSecondary,
        selectedColor: ext.primary.withValues(alpha: AppAlphas.fillStrong),
        labelStyle: TextStyle(fontFamily: AppFonts.family,fontSize: 15 * textScaleFactor, fontWeight: FontWeight.w500, color: ext.ink),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ext.ink,
        contentTextStyle: TextStyle(fontFamily: AppFonts.family,color: ext.background, fontSize: 15 * textScaleFactor, fontWeight: FontWeight.w400),
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
    // 💳 CASH APP STYLE: Pesos más pesados, tamaños más grandes
    final baseBold = bold ? FontWeight.w800 : FontWeight.w700;  // Más pesado
    final titleBold = bold ? FontWeight.w900 : FontWeight.w800; // BLACK weight
    final normalWeight = bold ? FontWeight.w600 : FontWeight.w500;  // Medium por defecto

    return TextTheme(
      displayLarge: TextStyle(fontFamily: AppFonts.family,
        fontSize: 40 * scale,  // Más grande
        fontWeight: FontWeight.w900,  // BLACK
        color: ext.ink,
        letterSpacing: -1.2,
        height: 1.0,
      ),
      displayMedium: TextStyle(fontFamily: AppFonts.family,
        fontSize: 28 * scale,
        fontWeight: FontWeight.w800,
        color: ext.ink,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineLarge: TextStyle(fontFamily: AppFonts.family,
        fontSize: 32 * scale,  // AppBar titles
        fontWeight: FontWeight.w900,
        color: ext.ink,
        letterSpacing: -1.0,
        height: 1.0,
      ),
      headlineMedium: TextStyle(fontFamily: AppFonts.family,
        fontSize: 24 * scale,
        fontWeight: titleBold,
        color: ext.ink,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      titleLarge: TextStyle(fontFamily: AppFonts.family,
        fontSize: 22 * scale,
        fontWeight: baseBold,
        color: ext.ink,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleMedium: TextStyle(fontFamily: AppFonts.family,
        fontSize: 18 * scale,  // Card headers más grandes
        fontWeight: baseBold,
        color: ext.ink,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      bodyLarge: TextStyle(fontFamily: AppFonts.family,
        fontSize: 17 * scale,
        fontWeight: normalWeight,
        color: ext.ink,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      bodyMedium: TextStyle(fontFamily: AppFonts.family,
        fontSize: 15 * scale,  // Un poco más grande
        fontWeight: normalWeight,
        color: ext.muted,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      bodySmall: TextStyle(fontFamily: AppFonts.family,
        fontSize: 13 * scale,
        fontWeight: normalWeight,
        color: ext.muted,
        letterSpacing: 0,
        height: 1.3,
      ),
      labelLarge: TextStyle(fontFamily: AppFonts.family,
        fontSize: 17 * scale,
        fontWeight: baseBold,
        color: ext.ink,
        letterSpacing: -0.2,
      ),
      labelMedium: TextStyle(fontFamily: AppFonts.family,
        fontSize: 15 * scale,
        fontWeight: FontWeight.w600,
        color: ext.ink,
        letterSpacing: -0.1,
      ),
      labelSmall: TextStyle(fontFamily: AppFonts.family,
        fontSize: 12 * scale,
        fontWeight: FontWeight.w600,
        color: ext.muted,
        letterSpacing: 0,
      ),
    );
  }
}

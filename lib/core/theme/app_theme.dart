import 'package:flutter/material.dart';

import 'app_dimens.dart';

/// Paleta de colores alineada con el sistema de iOS (Human Interface Guidelines).
///
/// Los tokens reemplazan a la paleta "tech" anterior (#075BE8) por los
/// system colors de Apple, que se perciben más suaves y elegantes.
class AppColors {
  AppColors._();

  /// systemBlue — color primario de acciones y énfasis.
  static const primary = Color(0xFF007AFF);

  /// Variante oscura del primario para contraste sobre fondos claros.
  static const primaryDark = Color(0xFF004E8F);

  /// label — texto principal (negro cálido, no azulado).
  static const ink = Color(0xFF1C1C1E);

  /// systemGray — texto secundario, captions, iconos inactivos.
  static const muted = Color(0xFF8E8E93);

  /// separator — bordes y divisores.
  static const line = Color(0xFFE5E5EA);

  /// secondarySystemGroupedBackground — tarjetas y superficies elevadas.
  static const surface = Color(0xFFFFFFFF);

  /// systemGroupedBackground — fondo de pantalla, inputs rellenos.
  static const surfaceSecondary = Color(0xFFF2F2F7);

  /// Alias de fondo para la app (mismo grouped background).
  static const background = Color(0xFFF2F2F7);

  /// systemGreen — estados positivos, éxito, conectado.
  static const success = Color(0xFF34C759);

  /// systemOrange — advertencias, estado pendiente.
  static const warning = Color(0xFFFF9500);

  /// systemRed — errores, acciones destructivas, salidas.
  static const danger = Color(0xFFFF3B30);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.success,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      // No forzamos fontFamily: en iOS se renderiza SF Pro, en Android Roboto.
      // Esto da el efecto "híbrido elegante" nativo en cada plataforma.
      textTheme: const TextTheme(
        // Large Title (iOS) — 34pt w700
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        // Title (iOS) — títulos de pantalla
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        // Title 2 (iOS) — headers de sección, títulos destacados
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.2,
        ),
        // Title 3 (iOS) — títulos de tarjetas y celdas
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.1,
        ),
        // Body (iOS) — texto principal
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          letterSpacing: -0.1,
        ),
        // Caption (iOS) — metadatos, texto secundario
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
          letterSpacing: 0,
        ),
        // Button (iOS) — texto de botones
        labelLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.1,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        // Sin borde: la elevación visual la da la sombra del Card.shadowColor.
        shadowColor: AppColors.ink.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        // Inputs "fill" estilo iOS: sin outline visible en estado idle.
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdBorder,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdBorder,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdBorder,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.mdBorder,
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.mdBorder,
          ),
          side: const BorderSide(color: AppColors.line),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.line,
        thickness: 0.5,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        selectedColor: AppColors.primary.withValues(alpha: AppAlphas.fillStrong),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.pillBorder,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_theme.dart';

/// 🎨 Esquemas de color para la app
/// Cada esquema define una paleta completa para modo claro y oscuro
enum AppColorScheme {
  indigo('Corporativo', 'Profesional y moderno', LucideIcons.building2),
  emerald('Prosperidad', 'Crecimiento y éxito', LucideIcons.coins),
  sunset('Energía', 'Cálido y dinámico', LucideIcons.zap),
  ocean('Confianza', 'Estable y seguro', LucideIcons.shield),
  amethyst('Innovación', 'Creativo y visionario', LucideIcons.lightbulb),
  ruby('Impacto', 'Audaz y decidido', LucideIcons.target);

  const AppColorScheme(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  AppColorsExtension get light {
    switch (this) {
      case AppColorScheme.indigo:
        return AppColorsSchemes._indigo(Brightness.light);
      case AppColorScheme.emerald:
        return AppColorsSchemes._emerald(Brightness.light);
      case AppColorScheme.sunset:
        return AppColorsSchemes._sunset(Brightness.light);
      case AppColorScheme.ocean:
        return AppColorsSchemes._ocean(Brightness.light);
      case AppColorScheme.amethyst:
        return AppColorsSchemes._amethyst(Brightness.light);
      case AppColorScheme.ruby:
        return AppColorsSchemes._ruby(Brightness.light);
    }
  }

  AppColorsExtension get dark {
    switch (this) {
      case AppColorScheme.indigo:
        return AppColorsSchemes._indigo(Brightness.dark);
      case AppColorScheme.emerald:
        return AppColorsSchemes._emerald(Brightness.dark);
      case AppColorScheme.sunset:
        return AppColorsSchemes._sunset(Brightness.dark);
      case AppColorScheme.ocean:
        return AppColorsSchemes._ocean(Brightness.dark);
      case AppColorScheme.amethyst:
        return AppColorsSchemes._amethyst(Brightness.dark);
      case AppColorScheme.ruby:
        return AppColorsSchemes._ruby(Brightness.dark);
    }
  }

  static AppColorScheme fromString(String value) {
    return AppColorScheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppColorScheme.indigo,
    );
  }
}

extension AppColorsSchemes on AppColorsExtension {
  /// 💼 CORPORATIVO — Profesional, confiable, moderno
  /// Neutros fríos con acento índigo. Fondo sutilmente azulado.
  static AppColorsExtension _indigo(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF4F46E5),
        primaryDark: Color(0xFF4338CA),
        ink: Color(0xFF1A1A2E),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE2E4EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFEEF0F6),
        background: Color(0xFFF8F9FC),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFF8B5CF6),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFF818CF8),
        primaryDark: Color(0xFFA5B4FC),
        ink: Color(0xFFEEEEF4),
        muted: Color(0xFF8B8DA8),
        line: Color(0xFF2D2E4A),
        surface: Color(0xFF1A1B2E),
        surfaceSecondary: Color(0xFF12132A),
        background: Color(0xFF0E0F1A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFA78BFA),
      );
    }
  }

  /// 💰 PROSPERIDAD — Fresco, natural, crecimiento
  /// Neutros cálido-verdosos con acento esmeralda. Fondo con tinte verde.
  static AppColorsExtension _emerald(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF059669),
        primaryDark: Color(0xFF047857),
        ink: Color(0xFF1A2E1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE2EBE5),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFECF7F0),
        background: Color(0xFFF8FAF7),
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        danger: Color(0xFFDC2626),
        info: Color(0xFF0891B2),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFF34D399),
        primaryDark: Color(0xFF6EE7B7),
        ink: Color(0xFFEEF4F0),
        muted: Color(0xFF8BA898),
        line: Color(0xFF2A4A38),
        surface: Color(0xFF1A2E22),
        surfaceSecondary: Color(0xFF0F1A14),
        background: Color(0xFF0F1A14),
        success: Color(0xFF6EE7B7),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFF22D3EE),
      );
    }
  }

  /// ⚡ ENERGÍA — Cálido, dinámico, vibrante
  /// Neutros cálidos con acento naranja. Inspirado en atardecer.
  static AppColorsExtension _sunset(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFFEA580C),
        primaryDark: Color(0xFFC2410C),
        ink: Color(0xFF2E1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFF0E6DE),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFFFF5ED),
        background: Color(0xFFFEFAF7),
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        danger: Color(0xFFDC2626),
        info: Color(0xFFDB2777),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFFFB923C),
        primaryDark: Color(0xFFFDBBF7),
        ink: Color(0xFFF4F0EE),
        muted: Color(0xFFA89888),
        line: Color(0xFF4A3A2A),
        surface: Color(0xFF2E221A),
        surfaceSecondary: Color(0xFF1A120E),
        background: Color(0xFF1A120E),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFF472B6),
      );
    }
  }

  /// 🛡️ CONFIANZA — Calmado, estable, seguro
  /// Neutros frío-azulados con acento océano. Fondo como cielo claro.
  static AppColorsExtension _ocean(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF0284C7),
        primaryDark: Color(0xFF0369A1),
        ink: Color(0xFF1A1A2E),
        muted: Color(0xFF6B7280),
        line: Color(0xFFDEE7F0),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFEDF4FA),
        background: Color(0xFFF7FAFC),
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        danger: Color(0xFFDC2626),
        info: Color(0xFF0891B2),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFF38BDF8),
        primaryDark: Color(0xFF7DD3FC),
        ink: Color(0xFFEEF0F4),
        muted: Color(0xFF889EA8),
        line: Color(0xFF2A3E4A),
        surface: Color(0xFF1A2632),
        surfaceSecondary: Color(0xFF0E141A),
        background: Color(0xFF0E141A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFF22D3EE),
      );
    }
  }

  /// 💡 INNOVACIÓN — Creativo, visionario, único
  /// Neutros violáceos con acento amatista. Fondo con tinte púrpura.
  static AppColorsExtension _amethyst(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF7C3AED),
        primaryDark: Color(0xFF6D28D9),
        ink: Color(0xFF1E1A2E),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE8E2F0),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFF3EEF8),
        background: Color(0xFFFAF8FC),
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        danger: Color(0xFFDC2626),
        info: Color(0xFF7C3AED),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFFA78BFA),
        primaryDark: Color(0xFFC4B5FD),
        ink: Color(0xFFF2EEF6),
        muted: Color(0xFF9E88B0),
        line: Color(0xFF3A2A4A),
        surface: Color(0xFF221A32),
        surfaceSecondary: Color(0xFF14101A),
        background: Color(0xFF14101A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFC4B5FD),
      );
    }
  }

  /// 🎯 IMPACTO — Audaz, apasionado, decidido
  /// Neutros cálido-rosados con acento rubí. Fondo con tinte rojo suave.
  static AppColorsExtension _ruby(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFFDC2626),
        primaryDark: Color(0xFFB91C1C),
        ink: Color(0xFF2E1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFF0E2E2),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFFEEEEE),
        background: Color(0xFFFEF8F8),
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        danger: Color(0xFFDC2626),
        info: Color(0xFFDB2777),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFFF87171),
        primaryDark: Color(0xFFFCA5A5),
        ink: Color(0xFFF4EEEE),
        muted: Color(0xFFA88888),
        line: Color(0xFF4A2A2A),
        surface: Color(0xFF2E1A1A),
        surfaceSecondary: Color(0xFF1A0E0E),
        background: Color(0xFF1A0E0E),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFFCA5A5),
        info: Color(0xFFF472B6),
      );
    }
  }
}

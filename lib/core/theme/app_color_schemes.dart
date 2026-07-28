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

  /// Obtiene los colores para modo claro
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

  /// Obtiene los colores para modo oscuro
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

  /// Convierte desde string guardado en preferences
  static AppColorScheme fromString(String value) {
    return AppColorScheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppColorScheme.indigo,
    );
  }
}

extension AppColorsSchemes on AppColorsExtension {
  // ══════════════════════════════════════════════════════════════════════════
  // 💼 CORPORATIVO — Profesional y moderno (original)
  // ══════════════════════════════════════════════════════════════════════════
  static AppColorsExtension _indigo(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF4F46E5),
        primaryDark: Color(0xFF4338CA),
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE5E7EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFF3F4F6),
        background: Color(0xFFFAFAFA),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFF8B5CF6),
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFF818CF8),
        primaryDark: Color(0xFFA5B4FC),
        ink: Color(0xFFFAFAFA),
        muted: Color(0xFF9CA3AF),
        line: Color(0xFF374151),
        surface: Color(0xFF1F2937),
        surfaceSecondary: Color(0xFF111827),
        background: Color(0xFF0F172A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFA78BFA),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 💰 PROSPERIDAD — Crecimiento y éxito
  // ══════════════════════════════════════════════════════════════════════════
  static AppColorsExtension _emerald(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF059669), // Emerald 600
        primaryDark: Color(0xFF047857), // Emerald 700
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE5E7EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFF0FDF4), // Emerald tint
        background: Color(0xFFFAFAFA),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFF06B6D4), // Cyan
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFF34D399), // Emerald 400
        primaryDark: Color(0xFF6EE7B7), // Emerald 300
        ink: Color(0xFFFAFAFA),
        muted: Color(0xFF9CA3AF),
        line: Color(0xFF374151),
        surface: Color(0xFF1F2937),
        surfaceSecondary: Color(0xFF111827),
        background: Color(0xFF0F172A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFF22D3EE),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ⚡ ENERGÍA — Cálido y dinámico
  // ══════════════════════════════════════════════════════════════════════════
  static AppColorsExtension _sunset(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFFEA580C), // Orange 600
        primaryDark: Color(0xFFC2410C), // Orange 700
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE5E7EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFFFF7ED), // Orange tint
        background: Color(0xFFFAFAFA),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFFEC4899), // Pink
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFFFB923C), // Orange 400
        primaryDark: Color(0xFFFDBBF7), // Orange 300
        ink: Color(0xFFFAFAFA),
        muted: Color(0xFF9CA3AF),
        line: Color(0xFF374151),
        surface: Color(0xFF1F2937),
        surfaceSecondary: Color(0xFF111827),
        background: Color(0xFF0F172A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFF472B6),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🛡️ CONFIANZA — Estable y seguro
  // ══════════════════════════════════════════════════════════════════════════
  static AppColorsExtension _ocean(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF0284C7), // Sky 600
        primaryDark: Color(0xFF0369A1), // Sky 700
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE5E7EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFF0F9FF), // Sky tint
        background: Color(0xFFFAFAFA),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFF06B6D4), // Cyan
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFF38BDF8), // Sky 400
        primaryDark: Color(0xFF7DD3FC), // Sky 300
        ink: Color(0xFFFAFAFA),
        muted: Color(0xFF9CA3AF),
        line: Color(0xFF374151),
        surface: Color(0xFF1F2937),
        surfaceSecondary: Color(0xFF111827),
        background: Color(0xFF0F172A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFF22D3EE),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 💡 INNOVACIÓN — Creativo y visionario
  // ══════════════════════════════════════════════════════════════════════════
  static AppColorsExtension _amethyst(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFF7C3AED), // Violet 600
        primaryDark: Color(0xFF6D28D9), // Violet 700
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE5E7EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFF5F3FF), // Violet tint
        background: Color(0xFFFAFAFA),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFF8B5CF6), // Violet
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFFA78BFA), // Violet 400
        primaryDark: Color(0xFFC4B5FD), // Violet 300
        ink: Color(0xFFFAFAFA),
        muted: Color(0xFF9CA3AF),
        line: Color(0xFF374151),
        surface: Color(0xFF1F2937),
        surfaceSecondary: Color(0xFF111827),
        background: Color(0xFF0F172A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFA78BFA),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🎯 IMPACTO — Audaz y decidido
  // ══════════════════════════════════════════════════════════════════════════
  static AppColorsExtension _ruby(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const AppColorsExtension(
        primary: Color(0xFFDC2626), // Red 600
        primaryDark: Color(0xFFB91C1C), // Red 700
        ink: Color(0xFF1A1A1A),
        muted: Color(0xFF6B7280),
        line: Color(0xFFE5E7EB),
        surface: Color(0xFFFFFFFF),
        surfaceSecondary: Color(0xFFFEF2F2), // Red tint
        background: Color(0xFFFAFAFA),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        danger: Color(0xFFEF4444),
        info: Color(0xFFEC4899), // Pink
      );
    } else {
      return const AppColorsExtension(
        primary: Color(0xFFF87171), // Red 400
        primaryDark: Color(0xFFFCA5A5), // Red 300
        ink: Color(0xFFFAFAFA),
        muted: Color(0xFF9CA3AF),
        line: Color(0xFF374151),
        surface: Color(0xFF1F2937),
        surfaceSecondary: Color(0xFF111827),
        background: Color(0xFF0F172A),
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        danger: Color(0xFFF87171),
        info: Color(0xFFF472B6),
      );
    }
  }
}

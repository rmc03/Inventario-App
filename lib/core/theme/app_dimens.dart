import 'package:flutter/material.dart';

/// Design tokens centralizados — Cash App Style.
///
/// Radii grandes, espaciado generoso, estilo minimalista premium.
class AppRadii {
  AppRadii._();

  /// Radio pequeño (badges, chips pequeños).
  static const sm = 10.0;

  /// Radio medio (botones estándar).
  static const md = 16.0;

  /// Radio grande (cards principales) — Cash App style.
  static const lg = 20.0;

  /// Radio extra grande (hero cards, containers destacados).
  static const xl = 24.0;

  /// Radio de píldora completa (botones pill, tags).
  static const pill = 999.0;

  static const smBorder = BorderRadius.all(Radius.circular(sm));
  static const mdBorder = BorderRadius.all(Radius.circular(md));
  static const lgBorder = BorderRadius.all(Radius.circular(lg));
  static const xlBorder = BorderRadius.all(Radius.circular(xl));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}


/// Escala de opacidad para fondos, bordes y overlays translúcidos.
///
/// Deriva siempre de [AppColors] (nunca de literales), pero el alpha se
/// normaliza aquí para evitar los 11 valores distintos que había dispersos.
class AppAlphas {
  AppAlphas._();

  /// Relleno suave (fondos de tinte, iconos activos).
  static const fill = 0.08;

  /// Relleno marcado (estados seleccionados, banners).
  static const fillStrong = 0.12;

  /// Borde translúcido (separadores sobre tinte).
  static const border = 0.20;

  /// Overlay modal o scrim.
  static const overlay = 0.40;
}

/// Escala de sombras. Hoy solo hace falta una: la sombra sutil de iOS.
class AppShadows {
  AppShadows._();

  /// Sombra suave, elevación mínima — sustituye a las BoxShadow duplicadas
  /// que había en `producto_form_screen.dart`.
  static final subtle = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF1C1C1E).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Espaciado base de 4px — Cash App style (más generoso).
class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;   // Aumentado de 12 para más respiro
  static const lg = 20.0;   // Aumentado de 16
  static const xl = 24.0;   // Aumentado de 20
  static const xxl = 32.0;  // Aumentado de 24
  static const xxxl = 40.0; // Nuevo — para separaciones grandes
}

/// Familia tipográfica de la app.
///
/// Roboto: la fuente predeterminada de Material Design.
/// Neutral, profesional, universalmente disponible.
/// Excepcionalmente legible en pantallas de todos los tamaños.
class AppFonts {
  AppFonts._();

  /// Roboto - fuente del sistema Material Design
  /// Neutral, profesional, siempre disponible en Flutter
  static const String family = 'Roboto';

  /// Tamaño mínimo de fuente para legibilidad.
  static const double floor = 11.0;
}

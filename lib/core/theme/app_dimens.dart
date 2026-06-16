import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Design tokens centralizados.
///
/// Reemplazan los magic numbers dispersos por la app (radios de 6/8/10/12/14/20,
/// alphas de 0.025 a 0.72, BoxShadows duplicadas) por una escala única y consistente
/// alineada con el lenguaje visual de iOS.
class AppRadii {
  AppRadii._();

  /// Radio pequeño (badges, botones de control).
  static const sm = 8.0;

  /// Radio medio (inputs, chips, tarjetas internas).
  static const md = 12.0;

  /// Radio grande (cards principales, bottom sheets).
  static const lg = 16.0;

  /// Radio extra grande (hero images, contenedores destacados).
  static const xl = 20.0;

  /// Radio de píldora completa (botones tipo pill, buscadores).
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
      color: AppColors.ink.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Espaciado base de 4px. Mantiene consistencia entre pantallas.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

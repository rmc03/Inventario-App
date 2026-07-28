import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 🎨 Configuración centralizada de marca
/// Cambiar estos valores cuando tengas el branding definitivo
class AppBranding {
  AppBranding._();

  // 📝 PLACEHOLDER - Cambiar cuando tengas nombre definitivo
  static const String appName = 'MypiUtil';
  static const String appTagline = 'Tu mipyme, organizada';
  static const String appDescription =
      'Inventario, ventas y turnos. Todo sin internet.';

  /// Construye el ícono de la app (placeholder abstracto)
  /// Cambiar por AssetImage cuando tengas el ícono definitivo
  static Widget buildAppIcon(
    BuildContext context, {
    double size = 92,
  }) {
    final colors = context.colors;
    return _PlaceholderAppIcon(colors: colors, size: size);
  }
}

/// Ícono placeholder: diseño abstracto moderno
/// Tres rectángulos redondeados sobre gradiente radial
class _PlaceholderAppIcon extends StatelessWidget {
  const _PlaceholderAppIcon({
    required this.colors,
    required this.size,
  });

  final AppColorsExtension colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [colors.primary, colors.primaryDark],
          center: Alignment.topLeft,
          radius: 1.2,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(76), // 0.3 * 255
            blurRadius: size * 0.3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Tres rectángulos abstractos simbolizando items/productos
          _buildShapeBlock(size, 0.25, 0.20, 0.35, 0.25),
          _buildShapeBlock(size, 0.55, 0.35, 0.30, 0.40),
          _buildShapeBlock(size, 0.35, 0.60, 0.40, 0.22),
        ],
      ),
    );
  }

  Widget _buildShapeBlock(
    double size,
    double left,
    double top,
    double width,
    double height,
  ) {
    return Positioned(
      left: size * left,
      top: size * top,
      child: Container(
        width: size * width,
        height: size * height,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51), // 0.2 reducido de 0.25
          borderRadius: BorderRadius.circular(size * 0.08),
        ),
      ),
    );
  }
}

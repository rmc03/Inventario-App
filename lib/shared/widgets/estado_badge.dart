import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../models/cuadre.dart';

class EstadoBadge extends StatelessWidget {
  const EstadoBadge({
    super.key,
    required this.estado,
    this.showBorder = false,
  });

  final CuadreEstado estado;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      CuadreEstado.aprobado => context.colors.success,
      CuadreEstado.rechazado => context.colors.danger,
      CuadreEstado.pendiente => context.colors.warning,
    };
    final icon = switch (estado) {
      CuadreEstado.aprobado => Icons.check_circle_outline_rounded,
      CuadreEstado.rechazado => Icons.cancel_outlined,
      CuadreEstado.pendiente => Icons.schedule_rounded,
    };

    return Semantics(
      label: 'Estado: ${estado.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppAlphas.fillStrong),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: showBorder
              ? Border.all(
                  color: color.withValues(alpha: AppAlphas.fillStrong),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              estado.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

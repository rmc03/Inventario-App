import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Tarjeta de resumen de turno activo.
///
/// Muestra el total vendido (hero), ventas y unidades (secundarios),
/// y un badge de estado con la hora de inicio.
///
/// Diseñada para reutilizarse en:
/// - Turno activo (MiTurnoScreen)
/// - Historial de cuadres cerrados
/// - Resumen en Ajustes
class ShiftSummaryCard extends StatelessWidget {
  const ShiftSummaryCard({
    super.key,
    required this.totalVentas,
    required this.cantidadVentas,
    required this.cantidadUnidades,
    required this.activo,
    this.horaInicio,
  });

  final double totalVentas;
  final int cantidadVentas;
  final int cantidadUnidades;
  final bool activo;
  final DateTime? horaInicio;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: ext.line),
        boxShadow: [
          BoxShadow(
            color: ext.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Total del turno (hero) ──
          Text(
            'Total del turno',
            style: textTheme.bodyMedium?.copyWith(color: ext.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrency(totalVentas),
              style: textTheme.headlineLarge?.copyWith(
                color: ext.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: ext.line),
          const SizedBox(height: AppSpacing.md),

          // ── Stats secundarios: ventas + uds. ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatColumn(
                icon: Icons.shopping_cart_rounded,
                value: '$cantidadVentas',
                label: cantidadVentas == 1 ? 'venta' : 'ventas',
              ),
              Container(
                width: 1,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                color: ext.line,
              ),
              _StatColumn(
                icon: Icons.inventory_2_rounded,
                value: '$cantidadUnidades',
                label: cantidadUnidades == 1 ? 'ud.' : 'uds.',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: ext.line),
          const SizedBox(height: AppSpacing.md),

          // ── Badge de estado ──
          if (activo && horaInicio != null)
            _ShiftBadge(horaInicio: horaInicio!)
          else if (!activo)
            _ShiftBadge.closed(),
        ],
      ),
    );
  }
}

// ─── Stat column (ícono + valor + label) ─────────────────────────────────────

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: ext.muted),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: ext.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: ext.muted),
        ),
      ],
    );
  }
}

// ─── Badge chip ──────────────────────────────────────────────────────────────

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.horaInicio}) : closed = false;

  const _ShiftBadge.closed()
      : horaInicio = null,
        closed = true;

  final DateTime? horaInicio;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    final color = closed ? ext.muted : ext.success;
    final text = closed
        ? 'Turno cerrado'
        : 'Turno activo \u00b7 Desde ${timeFormatter.format(horaInicio!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            closed ? Icons.stop_circle_rounded : Icons.access_time_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

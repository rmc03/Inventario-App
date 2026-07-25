import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

/// Badge de stock estilo iOS: texto coloreado sobre fondo translúcido suave,
/// sin pesos excesivos.
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock, required this.isLow});

  final int stock;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isLow ? colors.danger : colors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      child: Semantics(
        label: '$stock unidades, stock ${isLow ? 'bajo' : 'suficiente'}',
        child: Text(
          '$stock unidades',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

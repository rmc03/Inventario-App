import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock, required this.isLow});

  final int stock;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final color = isLow ? AppColors.danger : AppColors.success;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          '$stock unidades',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

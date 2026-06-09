import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class QtyControls extends StatelessWidget {
  const QtyControls({
    super.key,
    required this.cantidad,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int cantidad;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 32,
          child: Text(
            '$cantidad',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class QtyBtn extends StatelessWidget {
  const QtyBtn({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: SizedBox.square(
          dimension: 30,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

/// Tarjeta de estadística estilo iOS: blanca, sin borde, con número destacado
/// en el color de acento. Sobria frente a la versión anterior (que usaba
/// fondo de color a un 8% de opacidad).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.tint,
  });

  final String label;
  final String value;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.colors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.mdBorder,
          ),
          shadows: AppShadows.subtle,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tint ?? context.colors.primary,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

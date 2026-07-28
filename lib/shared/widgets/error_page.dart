import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.uri, this.error, this.onRetry});

  final String uri;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Error',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.danger.withValues(alpha: AppAlphas.fill),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl + AppSpacing.xs),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 52,
                        color: context.colors.danger,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Página no encontrada',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'La ruta "$uri" no existe.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.muted,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  SizedBox(height: AppSpacing.md),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.danger.withValues(alpha: 0.1),
                      borderRadius: AppRadii.mdBorder,
                      border: Border.all(color: context.colors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.danger,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRetry != null) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Haptics.tap(context);
                          onRetry!();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reintentar'),
                      ),
                      SizedBox(width: AppSpacing.md),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        Haptics.tap(context);
                        context.go('/');
                      },
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text('Ir al inicio'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

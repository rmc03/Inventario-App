import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.uri});

  final String uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(28),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Página no encontrada',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'La ruta "$uri" no existe.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Ir al inicio'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/connectivity_service.dart';

class IndicadorConexion extends ConsumerWidget {
  const IndicadorConexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref
        .watch(connectivityStatusProvider)
        .when(
          data: (value) => value,
          error: (_, _) => true,
          loading: () => true,
        );
    final color = isConnected ? AppColors.success : AppColors.warning;
    final text = isConnected ? 'Conectado y sincronizado' : 'Modo offline';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.20)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

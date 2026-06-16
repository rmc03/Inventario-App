import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/connectivity_service.dart';

/// Indicador de conexión compacto estilo iOS.
///
/// Antes era un banner ancho con fondo de color al 10%. Ahora es una fila
/// discreta con un punto de estado + texto, mucho menos invasiva.
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

    // Solo mostramos el banner cuando hay algo que avisar (offline).
    // Con conexión no ocupamos espacio vertical en cada pantalla.
    if (isConnected) {
      return const SizedBox.shrink();
    }

    final color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Offline',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

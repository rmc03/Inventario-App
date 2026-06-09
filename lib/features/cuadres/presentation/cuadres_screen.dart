import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../providers/cuadre_provider.dart';

class CuadresScreen extends ConsumerWidget {
  const CuadresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuadres = ref.watch(cuadreControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuadres')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final cuadre in cuadres) ...[
              Card(
                key: ValueKey(cuadre.id),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  onTap: () => context.go('/admin/cuadres/${cuadre.id}'),
                  title: Text(
                    compactDateFormatter.format(cuadre.fechaTurno),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(cuadre.dependienteNombre),
                  trailing: _EstadoBadge(estado: cuadre.estado),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final CuadreEstado estado;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      CuadreEstado.aprobado => AppColors.success,
      CuadreEstado.rechazado => AppColors.danger,
      CuadreEstado.pendiente => AppColors.warning,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          estado.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

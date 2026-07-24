import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../providers/cuadre_provider.dart';

class CuadresScreen extends ConsumerWidget {
  const CuadresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuadres = ref.watch(cuadreControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuadres'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
              ScreenMenuItem(
                value: 'filtrar',
                icon: Icons.filter_list_rounded,
                iconColor: context.colors.primary,
                title: 'Filtrar por fecha',
                subtitle: 'Rango de fechas',
                enabled: false,
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/admin/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final cuadre in cuadres) ...[
              Card(
                key: ValueKey(cuadre.id),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  onTap: () => context.push('/admin/cuadres/${cuadre.id}'),
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
      CuadreEstado.aprobado => context.colors.success,
      CuadreEstado.rechazado => context.colors.danger,
      CuadreEstado.pendiente => context.colors.warning,
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

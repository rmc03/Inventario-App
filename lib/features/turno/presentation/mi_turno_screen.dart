import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/venta.dart';
import '../../ventas/providers/venta_provider.dart';
import '../providers/turno_provider.dart';

class MiTurnoScreen extends ConsumerWidget {
  const MiTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);

    if (turno.estaActivo) {
      return const _TurnoActivoView();
    } else if (turno.cuadreEnviadoHoy) {
      return const _CuadreEnviadoView();
    } else {
      return const _SinTurnoView();
    }
  }
}

// ─── Estado 1: Sin turno activo ───────────────────────────────────────────────

class _SinTurnoView extends ConsumerWidget {
  const _SinTurnoView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi turno')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(28),
                  child: Icon(
                    Icons.work_outline_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                compactDateFormatter.format(DateTime.now()),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Aún no has iniciado tu turno',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(turnoControllerProvider.notifier).iniciarTurno(),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar turno'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Estado 2: Turno activo ───────────────────────────────────────────────────

class _TurnoActivoView extends ConsumerWidget {
  const _TurnoActivoView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);
    final ventas = ref.watch(ventasDelTurnoProvider);
    final totalTurno = ventas.fold(0.0, (sum, v) => sum + v.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          if (turno.horaInicio != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Turno activo • ${timeFormatter.format(turno.horaInicio!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final isWide = MediaQuery.of(context).size.width >= 360;
          return isWide
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/dependiente/turno/nueva-venta'),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Nueva venta'),
                )
              : FloatingActionButton(
                  onPressed: () => context.push('/dependiente/turno/nueva-venta'),
                  tooltip: 'Nueva venta',
                  child: const Icon(Icons.add_shopping_cart_rounded),
                );
        },
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Stats summary
            if (ventas.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${ventasLabel(ventas.length)} completada${ventas.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      formatCurrency(totalTurno),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            if (ventas.isNotEmpty) const Divider(height: 1),

            Expanded(
              child: ventas.isEmpty
                  ? const _EmptyItems()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80), // padding bottom for FAB
                      itemCount: ventas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _VentaCard(venta: ventas[i]),
                    ),
            ),
          ],
        ),
      ),
bottomNavigationBar: (turno.estaActivo && ventas.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/dependiente/turno/resumen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cerrar Turno y Enviar Cuadre'),
                ),
              ),
            )
          : null,
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: AppColors.muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin ventas aún',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca en "Nueva venta" para atender a un cliente.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VentaCard extends StatelessWidget {
  const _VentaCard({required this.venta});

  final Venta venta;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/dependiente/turno/venta/${venta.id}', extra: venta),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta a las ${timeFormatter.format(venta.fecha)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      articulosLabel(venta.totalUnidades),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(venta.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Estado 3: Cuadre enviado ─────────────────────────────────────────────────

class _CuadreEnviadoView extends StatelessWidget {
  const _CuadreEnviadoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi turno')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(28),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 56,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cuadre enviado',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pendiente de revisión por el jefe.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Hoy, ${compactDateFormatter.format(DateTime.now())}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

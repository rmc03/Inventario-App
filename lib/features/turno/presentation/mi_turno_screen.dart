import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre_item.dart';
import '../providers/turno_provider.dart';

class MiTurnoScreen extends ConsumerWidget {
  const MiTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);

    if (turno.estaActivo) {
      return _TurnoActivoView(turno: turno);
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(turnoControllerProvider.notifier).iniciarTurno(),
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

class _TurnoActivoView extends StatelessWidget {
  const _TurnoActivoView({required this.turno});

  final TurnoState turno;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          if (turno.horaInicio != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.success,
                          size: 8,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Desde ${timeFormatter.format(turno.horaInicio!)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: turno.items.isEmpty
                  ? const _EmptyItems()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      itemCount: turno.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _TurnoItemCard(item: turno.items[i]),
                    ),
            ),
            _TotalBar(turno: turno),
          ],
        ),
      ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ve al inventario y toca un producto\npara añadirlo al cuadre.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnoItemCard extends ConsumerWidget {
  const _TurnoItemCard({required this.item});

  final CuadreItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productoNombre,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCurrency(item.precioUnitario)} c/u',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _QtyControls(
              cantidad: item.cantidad,
              onDecrement: item.cantidad > 1
                  ? () => ref
                      .read(turnoControllerProvider.notifier)
                      .actualizarCantidadItem(item.productoId, item.cantidad - 1)
                  : null,
              onIncrement: () => ref
                  .read(turnoControllerProvider.notifier)
                  .actualizarCantidadItem(item.productoId, item.cantidad + 1),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(item.subtotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => ref
                      .read(turnoControllerProvider.notifier)
                      .eliminarItem(item.productoId),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControls extends StatelessWidget {
  const _QtyControls({
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
        _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 32,
          child: Text(
            '$cantidad',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

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

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.turno});

  final TurnoState turno;

  @override
  Widget build(BuildContext context) {
    final isEmpty = turno.items.isEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${turno.items.length} '
                      '${turno.items.length == 1 ? 'producto' : 'productos'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      formatCurrency(turno.valorTotal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: isEmpty
                    ? null
                    : () => context.push('/dependiente/turno/resumen'),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Enviar cuadre'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                      ),
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

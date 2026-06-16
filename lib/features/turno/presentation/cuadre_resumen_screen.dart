import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre_item.dart';
import '../../../shared/widgets/qty_controls.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../providers/turno_provider.dart';

class CuadreResumenScreen extends ConsumerWidget {
  const CuadreResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del turno'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  _ResumenHeader(turno: turno),
                  const SizedBox(height: 16),
                  if (turno.items.isEmpty)
                    const _EmptyResumen()
                  else ...[
                    for (final item in turno.items) ...[
                      _ResumenItemCard(item: item),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    const Divider(),
                    const SizedBox(height: 12),
                    _ResumenTotal(turno: turno),
                  ],
                ],
              ),
            ),
            _ConfirmBar(
              enabled: turno.items.isNotEmpty,
              onConfirm: () => _confirmarEnvio(context, ref, turno),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEnvio(
    BuildContext context,
    WidgetRef ref,
    TurnoState turno,
  ) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null || turno.items.isEmpty) return;

    final error = ref
        .read(cuadreControllerProvider.notifier)
        .crearCuadrePendiente(dependiente: user, items: turno.items);

    if (error != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    ref.read(turnoControllerProvider.notifier).enviarCuadre();
    if (context.mounted) context.go('/dependiente/turno');
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _ResumenHeader extends StatelessWidget {
  const _ResumenHeader({required this.turno});

  final TurnoState turno;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compactDateFormatter.format(DateTime.now()),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (turno.horaInicio != null)
                Text(
                  'Turno iniciado a las ${timeFormatter.format(turno.horaInicio!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'Revisar antes de enviar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenItemCard extends ConsumerWidget {
  const _ResumenItemCard({required this.item});

  final CuadreItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
            QtyControls(
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


class _ResumenTotal extends StatelessWidget {
  const _ResumenTotal({required this.turno});

  final TurnoState turno;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${turno.items.length} '
              '${turno.items.length == 1 ? 'producto' : 'productos'} · '
              '${turno.totalUnidades} unidades',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Total de ventas',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        Text(
          formatCurrency(turno.valorTotal),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }
}

class _EmptyResumen extends StatelessWidget {
  const _EmptyResumen();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No hay ítems en el cuadre.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.enabled, required this.onConfirm});

  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: enabled ? onConfirm : null,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Confirmar y enviar'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

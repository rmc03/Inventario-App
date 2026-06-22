import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/venta.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../providers/turno_provider.dart';
import '../../ventas/providers/venta_provider.dart';

class CuadreResumenScreen extends ConsumerWidget {
  const CuadreResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);
    final ventas = ref.watch(ventasDelTurnoProvider);

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
                  if (ventas.isEmpty)
                    const _EmptyResumen()
                  else ...[
                    for (final venta in ventas) ...[
                      _ResumenVentaCard(venta: venta),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    const Divider(),
                    const SizedBox(height: 12),
                    _ResumenTotal(ventas: ventas),
                  ],
                ],
              ),
            ),
            _ConfirmBar(
              enabled: ventas.isNotEmpty,
              onConfirm: () => _confirmarEnvio(context, ref, ventas),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEnvio(
    BuildContext context,
    WidgetRef ref,
    List<Venta> ventas,
  ) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null || ventas.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Enviar cuadre?'),
        content: const Text(
          'Se generará un cuadre pendiente para que el jefe lo revise. '
          '¿Deseas enviarlo ahora?',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final error = ref
        .read(cuadreControllerProvider.notifier)
        .crearCuadrePendiente(dependiente: user, ventas: ventas);

    if (error != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    ref.read(ventasDelTurnoProvider.notifier).clearVentas();
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

class _ResumenVentaCard extends StatelessWidget {
  const _ResumenVentaCard({required this.venta});

  final Venta venta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Venta a las ${timeFormatter.format(venta.fecha)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            '${venta.items.length} ${venta.items.length == 1 ? 'producto' : 'productos'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Text(
            formatCurrency(venta.total),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            for (final item in venta.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.productoNombre}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      formatCurrency(item.subtotal),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResumenTotal extends StatelessWidget {
  const _ResumenTotal({required this.ventas});

  final List<Venta> ventas;

  @override
  Widget build(BuildContext context) {
    final total = ventas.fold(0.0, (sum, v) => sum + v.total);
    final totalUnidades = ventas.fold(0, (sum, v) => sum + v.totalUnidades);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ventasLabel(ventas.length)} · $totalUnidades unidades',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Total de ventas',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Text(
          formatCurrency(total),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
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
          'No hay ventas en este turno.',
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
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
    );
  }
}

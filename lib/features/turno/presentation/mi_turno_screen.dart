import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/movimiento.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../providers/turno_provider.dart';

class MiTurnoScreen extends ConsumerWidget {
  const MiTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos = ref.watch(movimientosTurnoProvider);
    final turno = ref.watch(turnoControllerProvider);
    final entradas = movimientos
        .where((movimiento) => movimiento.tipo == MovimientoTipo.entrada)
        .fold(0, (total, movimiento) => total + movimiento.cantidad);
    final salidas = movimientos
        .where((movimiento) => movimiento.tipo == MovimientoTipo.salida)
        .fold(0, (total, movimiento) => total + movimiento.cantidad);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi turno')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                _TurnoMetric(
                  label: 'Entradas',
                  value: entradas.toString(),
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                _TurnoMetric(
                  label: 'Salidas',
                  value: salidas.toString(),
                  color: AppColors.danger,
                ),
              ],
            ),
            if (turno.cerradoHoy) ...[
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.20),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock_rounded, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(child: Text('Turno cerrado por hoy')),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              compactDateFormatter.format(DateTime.now()),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (movimientos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Aún no hay movimientos en este turno.'),
                ),
              )
            else
              for (final movimiento in movimientos) ...[
                _TurnoMovimiento(movimiento: movimiento),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: turno.cerradoHoy
                  ? null
                  : () {
                      final user = ref.read(authControllerProvider).user;
                      if (user == null) {
                        return;
                      }
                      ref
                          .read(cuadreControllerProvider.notifier)
                          .crearCuadrePendiente(
                            dependiente: user,
                            movimientos: movimientos,
                          );
                      ref.read(turnoControllerProvider.notifier).cerrarTurno();
                    },
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Cerrar turno'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnoMetric extends StatelessWidget {
  const _TurnoMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnoMovimiento extends StatelessWidget {
  const _TurnoMovimiento({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final isEntrada = movimiento.tipo == MovimientoTipo.entrada;
    final color = isEntrada ? AppColors.success : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isEntrada ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimiento.productoNombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movimiento.tipo.label} · ${movimiento.cantidad} unidades · ${timeFormatter.format(movimiento.fecha)}',
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

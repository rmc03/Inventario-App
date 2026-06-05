import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/movimiento.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../providers/cuadre_provider.dart';

class CuadreDetalleScreen extends ConsumerWidget {
  const CuadreDetalleScreen({super.key, required this.cuadreId});

  final String cuadreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuadre = ref
        .watch(cuadreControllerProvider.notifier)
        .findCuadre(cuadreId);

    if (cuadre == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del cuadre')),
        body: const Center(child: Text('Cuadre no encontrado')),
      );
    }

    final movimientos = ref.watch(movimientoControllerProvider).where((item) {
      return item.usuarioId == cuadre.dependienteId &&
          item.fecha.year == cuadre.fechaTurno.year &&
          item.fecha.month == cuadre.fechaTurno.month &&
          item.fecha.day == cuadre.fechaTurno.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del cuadre'),
        leading: IconButton(
          onPressed: () => context.go('/admin/cuadres'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              cuadre.dependienteNombre,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              compactDateFormatter.format(cuadre.fechaTurno),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SummaryBox(
                  label: 'Entradas',
                  value: cuadre.totalEntradas.toString(),
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                _SummaryBox(
                  label: 'Salidas',
                  value: cuadre.totalSalidas.toString(),
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Movimientos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (movimientos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Sin movimientos asociados al cuadre.'),
                ),
              )
            else
              for (final movimiento in movimientos) ...[
                Card(
                  child: ListTile(
                    leading: Icon(
                      movimiento.tipo == MovimientoTipo.entrada
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: movimiento.tipo == MovimientoTipo.entrada
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    title: Text(movimiento.productoNombre),
                    subtitle: Text(
                      '${movimiento.tipo.label} · ${movimiento.cantidad} · ${timeFormatter.format(movimiento.fecha)}',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 22),
            if (cuadre.estado == CuadreEstado.pendiente) ...[
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(cuadreControllerProvider.notifier)
                      .actualizarEstado(
                        id: cuadre.id,
                        estado: CuadreEstado.aprobado,
                      );
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Aprobar'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _reject(context, ref, cuadre),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Rechazar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Estado: ${cuadre.estado.label}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    Cuadre cuadre,
  ) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechazar cuadre'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Comentario obligatorio',
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (comment != null && comment.isNotEmpty) {
      ref
          .read(cuadreControllerProvider.notifier)
          .actualizarEstado(
            id: cuadre.id,
            estado: CuadreEstado.rechazado,
            comentarioJefe: comment,
          );
    }
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
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

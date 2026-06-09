import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/movimiento.dart';
import '../providers/movimiento_provider.dart';

class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  MovimientoTipo? _tipo;

  @override
  Widget build(BuildContext context) {
    final movimientos = ref.watch(movimientoControllerProvider).where((item) {
      return _tipo == null || item.tipo == _tipo;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _tipo == null,
                  onTap: () => setState(() => _tipo = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Entradas',
                  selected: _tipo == MovimientoTipo.entrada,
                  onTap: () => setState(() => _tipo = MovimientoTipo.entrada),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Salidas',
                  selected: _tipo == MovimientoTipo.salida,
                  onTap: () => setState(() => _tipo = MovimientoTipo.salida),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final movimiento in movimientos) ...[
              _MovimientoCard(key: ValueKey(movimiento.id), movimiento: movimiento),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.white,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  const _MovimientoCard({super.key, required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final isEntrada = movimiento.tipo == MovimientoTipo.entrada;
    final color = isEntrada ? AppColors.success : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  isEntrada
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                ),
              ),
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
                    '${movimiento.tipo.label} · ${movimiento.cantidad} unidades',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movimiento.usuarioNombre} · ${compactDateFormatter.format(movimiento.fecha)} ${timeFormatter.format(movimiento.fecha)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (movimiento.nota != null) ...[
                    const SizedBox(height: 6),
                    Text(movimiento.nota!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

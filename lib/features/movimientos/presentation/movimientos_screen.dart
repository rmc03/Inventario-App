import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

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

    // Group movimientos by day (date part only)
    final Map<DateTime, List<Movimiento>> grouped = {};
    for (final m in movimientos) {
      final day = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      grouped.putIfAbsent(day, () => []).add(m);
    }

    // Sort days descending (newest first)
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    String dateHeader(DateTime day) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      if (day == today) return 'Hoy';
      if (day == yesterday) return 'Ayer';
      return compactDateFormatter.format(day);
    }

    

    // Build the content list imperatively so we can aggregate movements
    // before constructing widgets.
    final List<Widget> content = [];
    content.addAll([
      SegmentedButton<MovimientoTipo?>(
        segments: const [
          ButtonSegment(value: null, label: Text('Todos')),
          ButtonSegment(value: MovimientoTipo.entrada, label: Text('Entradas')),
          ButtonSegment(value: MovimientoTipo.salida, label: Text('Salidas')),
        ],
        selected: {_tipo},
        onSelectionChanged: (value) => setState(() => _tipo = value.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      const SizedBox(height: 16),
    ]);

    if (movimientos.isEmpty) {
      content.addAll([
        const SizedBox(height: 60),
        Center(child: Text('No hay movimientos', style: Theme.of(context).textTheme.bodyLarge)),
      ]);
    } else {
      for (final day in days) {
        content.add(
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(dateHeader(day), style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        );
        content.add(const SizedBox(height: 8));

        final dayList = grouped[day]!;
        dayList.sort((a, b) => b.fecha.compareTo(a.fecha));

        List<Movimiento> aggregateByMinute(List<Movimiento> list) {
          final Map<String, Movimiento> acc = {};
          for (final m in list) {
            final truncated = DateTime(m.fecha.year, m.fecha.month, m.fecha.day, m.fecha.hour, m.fecha.minute);
            final key = '${m.productoId}|${m.tipo.name}|${m.usuarioId}|${truncated.toIso8601String()}';
            if (!acc.containsKey(key)) {
              acc[key] = Movimiento(
                id: const Uuid().v4(),
                productoId: m.productoId,
                productoNombre: m.productoNombre,
                usuarioId: m.usuarioId,
                usuarioNombre: m.usuarioNombre,
                usuarioFotoUrl: m.usuarioFotoUrl,
                tipo: m.tipo,
                cantidad: m.cantidad,
                nota: m.nota,
                fecha: truncated,
                synced: m.synced,
                createdAt: m.createdAt,
              );
            } else {
              final prev = acc[key]!;
              acc[key] = Movimiento(
                id: prev.id,
                productoId: prev.productoId,
                productoNombre: prev.productoNombre,
                usuarioId: prev.usuarioId,
                usuarioNombre: prev.usuarioNombre,
                usuarioFotoUrl: prev.usuarioFotoUrl,
                tipo: prev.tipo,
                cantidad: prev.cantidad + m.cantidad,
                nota: prev.nota ?? m.nota,
                fecha: prev.fecha,
                synced: prev.synced && m.synced,
                createdAt: prev.createdAt.isBefore(m.createdAt) ? prev.createdAt : m.createdAt,
              );
            }
          }
          return acc.values.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
        }

        final aggregated = aggregateByMinute(dayList);
        for (final m in aggregated) {
          content.add(_MovimientoCard(key: ValueKey(m.id), movimiento: m));
          content.add(const Divider());
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: content,
        ),
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  const _MovimientoCard({super.key, required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final isEntrada = movimiento.tipo == MovimientoTipo.entrada;
    // Detect pending sales (created by Turno flow). We classify as pending
    // when nota mentions 'turno' or 'pendiente'. This avoids confusing
    // pending ventas with confirmed 'salida' stock adjustments.
    final notaLower = movimiento.nota?.toLowerCase() ?? '';
    final isPendingSale = !isEntrada && (
      notaLower.contains('turno') ||
      notaLower.contains('pendiente') ||
      notaLower.contains('ajust') ||
      notaLower.contains('reducc') ||
      movimiento.cantidad < 0
    );
    final color = isEntrada
        ? AppColors.success
        : (isPendingSale ? AppColors.warning : AppColors.danger);

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
                    (() {
                      final qty = movimiento.cantidad.abs();
                      final baseLabel = isEntrada
                          ? movimiento.tipo.label
                          : (isPendingSale ? 'Venta (Pendiente)' : movimiento.tipo.label);
                      final suffix = movimiento.cantidad < 0 ? ' (reducción)' : '';
                      return '$baseLabel · $qty unidades$suffix';
                    })(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Omitir el nombre del usuario en entradas (solo muestra fecha/hora)
                    movimiento.tipo == MovimientoTipo.entrada
                        ? '${compactDateFormatter.format(movimiento.fecha)} ${timeFormatter.format(movimiento.fecha)}'
                        : '${movimiento.usuarioNombre} · ${compactDateFormatter.format(movimiento.fecha)} ${timeFormatter.format(movimiento.fecha)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (movimiento.nota != null) ...[
                    const SizedBox(height: 6),
                    Text(movimiento.nota!),
                  ],
                ],
              ),
            ),
            if (!isEntrada && movimiento.usuarioFotoUrl != null) ...[
              const SizedBox(width: 12),
              Builder(builder: (context) {
                final url = movimiento.usuarioFotoUrl!;
                final image = url.startsWith('http')
                    ? NetworkImage(url)
                    : FileImage(File(url)) as ImageProvider;
                return CircleAvatar(
                  radius: 20,
                  backgroundImage: image,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

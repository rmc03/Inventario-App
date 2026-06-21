import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/movimiento.dart';
import '../providers/movimiento_provider.dart';

/// Entrada agregada para la lista de movimientos. Cada item es o bien una
/// cabecera de día, o bien una tarjeta de movimiento ya agregada por minuto.
sealed class _MovimientoItem {
  const _MovimientoItem();
}

class _DayHeaderItem extends _MovimientoItem {
  const _DayHeaderItem(this.day);
  final DateTime day;
}

class _MovimientoCardItem extends _MovimientoItem {
  const _MovimientoCardItem(this.movimiento);
  final Movimiento movimiento;
}

/// Agrega movimientos del mismo minuto (mismo producto/tipo/usuario) en uno
/// solo sumando cantidades. Se usa fuera de `build()` para no recalcular
/// (ni regenerar UUIDs) en cada frame.
List<Movimiento> _aggregateByMinute(List<Movimiento> list) {
  final Map<String, Movimiento> acc = {};
  for (final m in list) {
    final truncated = DateTime(
      m.fecha.year, m.fecha.month, m.fecha.day, m.fecha.hour, m.fecha.minute,
    );
    final key =
        '${m.productoId}|${m.tipo.name}|${m.usuarioId}|${truncated.toIso8601String()}';
    final prev = acc[key];
    if (prev == null) {
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
        createdAt:
            prev.createdAt.isBefore(m.createdAt) ? prev.createdAt : m.createdAt,
      );
    }
  }
  return acc.values.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
}

/// Construye la lista plana de items a renderizar (cabeceras de día + tarjetas)
/// a partir de los movimientos ya filtrados por tipo.
List<_MovimientoItem> _buildFlatItems(List<Movimiento> movimientos) {
  // Agrupar por día.
  final Map<DateTime, List<Movimiento>> grouped = {};
  for (final m in movimientos) {
    final day = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
    grouped.putIfAbsent(day, () => []).add(m);
  }
  final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  final List<_MovimientoItem> items = [];
  for (final day in days) {
    final dayList = grouped[day]!
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    items.add(_DayHeaderItem(day));
    for (final m in _aggregateByMinute(dayList)) {
      items.add(_MovimientoCardItem(m));
    }
  }
  return items;
}

class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  MovimientoTipo? _tipo;

  // Caché de la agregación: solo se recalcula cuando cambia la lista fuente
  // o el filtro activo. Evita regenerar UUIDs y reagrupar en cada rebuild.
  List<Movimiento>? _cachedSource;
  MovimientoTipo? _cachedTipo;
  late List<_MovimientoItem> _flatItems;

  List<_MovimientoItem> _resolveItems(List<Movimiento> source) {
    if (!identical(source, _cachedSource) || _tipo != _cachedTipo) {
      final filtered = _tipo == null
          ? source
          : source.where((m) => m.tipo == _tipo).toList();
      _flatItems = _buildFlatItems(filtered);
      _cachedSource = source;
      _cachedTipo = _tipo;
    }
    return _flatItems;
  }

  String _dateHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Hoy';
    if (day == yesterday) return 'Ayer';
    return compactDateFormatter.format(day);
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(movimientoControllerProvider);
    final items = _resolveItems(source);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0,
                ),
                child: SegmentedButton<MovimientoTipo?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('Todos')),
                    ButtonSegment(
                        value: MovimientoTipo.entrada, label: Text('Entradas')),
                    ButtonSegment(
                        value: MovimientoTipo.salida, label: Text('Salidas')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (value) =>
                      setState(() => _tipo = value.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Text('No hay movimientos'),
                  ],
                ),
              )
            else
              SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return switch (item) {
                    _DayHeaderItem(:final day) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.muted.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _dateHeader(day),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    _MovimientoCardItem(:final movimiento) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            _MovimientoCard(
                              key: ValueKey(movimiento.id),
                              movimiento: movimiento,
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                  };
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
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
              RepaintBoundary(
                child: _UsuarioAvatar(url: movimiento.usuarioFotoUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avatar de usuario con caché de resolución de imagen a tamaño pequeño,
/// para no decodificar fotos a resolución completa en un círculo de 40px.
class _UsuarioAvatar extends StatelessWidget {
  const _UsuarioAvatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    // 40px de radio = 80px diámetro → decodificamos a ~160px para retina.
    const cacheSize = 160;
    final image = url.startsWith('http')
        ? ResizeImage(NetworkImage(url), width: cacheSize, height: cacheSize)
        : ResizeImage(FileImage(File(url)), width: cacheSize, height: cacheSize)
            as ImageProvider;
    return CircleAvatar(radius: 20, backgroundImage: image);
  }
}

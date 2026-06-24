import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

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

class _VentaCardItem extends _MovimientoItem {
  const _VentaCardItem(this.ventaId, this.movimientos);
  final String ventaId;
  final List<Movimiento> movimientos;
}

class _ProductoAgrupado {
  final String productoId;
  final String productoNombre;
  final int totalUnidades;
  final List<Movimiento> movimientos;

  _ProductoAgrupado({
    required this.productoId,
    required this.productoNombre,
    required this.totalUnidades,
    required this.movimientos,
  });
}

List<_MovimientoItem> _buildFlatItems(List<Movimiento> movimientos) {
  final Map<DateTime, List<Movimiento>> grouped = {};
  for (final m in movimientos) {
    final day = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
    grouped.putIfAbsent(day, () => []).add(m);
  }
  final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  final List<_MovimientoItem> items = [];
  for (final day in days) {
    final dayList = grouped[day]!..sort((a, b) => b.fecha.compareTo(a.fecha));
    items.add(_DayHeaderItem(day));

    final processedSales = <String>{};
    for (final m in dayList) {
      if (m.tipo == MovimientoTipo.salida &&
          m.nota != null &&
          m.nota!.startsWith('Venta POS')) {
        final ventaId = m.nota!;
        if (!processedSales.contains(ventaId)) {
          processedSales.add(ventaId);
          final saleItems = dayList.where((x) => x.nota == ventaId).toList();
          items.add(_VentaCardItem(ventaId, saleItems));
        }
      } else {
        items.add(_MovimientoCardItem(m));
      }
    }
  }
  return items;
}

List<_ProductoAgrupado> _agruparPorProducto(List<Movimiento> movimientos) {
  final map = <String, _ProductoAgrupado>{};
  for (final m in movimientos) {
    final existing = map[m.productoId];
    if (existing != null) {
      map[m.productoId] = _ProductoAgrupado(
        productoId: m.productoId,
        productoNombre: m.productoNombre,
        totalUnidades: existing.totalUnidades + m.cantidad.abs(),
        movimientos: [...existing.movimientos, m],
      );
    } else {
      map[m.productoId] = _ProductoAgrupado(
        productoId: m.productoId,
        productoNombre: m.productoNombre,
        totalUnidades: m.cantidad.abs(),
        movimientos: [m],
      );
    }
  }
  final result = map.values.toList()
    ..sort((a, b) => b.totalUnidades.compareTo(a.totalUnidades));
  for (final p in result) {
    p.movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
  }
  return result;
}

class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  MovimientoTipo? _tipo;
  bool _mostrarProductos = true;

  List<Movimiento>? _cachedSource;
  MovimientoTipo? _cachedTipo;
  late List<_MovimientoItem> _ventasItems;
  late List<_ProductoAgrupado> _productosItems;

  void _resolveItems(List<Movimiento> source) {
    if (!identical(source, _cachedSource) || _tipo != _cachedTipo) {
      final filtered = _tipo == null
          ? source
          : source.where((m) => m.tipo == _tipo).toList();
      _ventasItems = _buildFlatItems(filtered);
      _productosItems = _agruparPorProducto(filtered);
      _cachedSource = source;
      _cachedTipo = _tipo;
    }
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
    _resolveItems(source);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Toggle ──
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: 'Productos',
                      icon: Icons.inventory_2_rounded,
                      selected: _mostrarProductos,
                      onTap: () => setState(() => _mostrarProductos = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Por ventas',
                      icon: Icons.receipt_long_rounded,
                      selected: !_mostrarProductos,
                      onTap: () => setState(() => _mostrarProductos = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Filtro ──
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: 'Todos',
                      icon: Icons.filter_list_rounded,
                      selected: _tipo == null,
                      onTap: () => setState(() => _tipo = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Entradas',
                      icon: Icons.arrow_downward_rounded,
                      selected: _tipo == MovimientoTipo.entrada,
                      onTap: () =>
                          setState(() => _tipo = MovimientoTipo.entrada),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Salidas',
                      icon: Icons.arrow_upward_rounded,
                      selected: _tipo == MovimientoTipo.salida,
                      onTap: () =>
                          setState(() => _tipo = MovimientoTipo.salida),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Contenido ──
            Expanded(
              child: _mostrarProductos
                  ? _buildProductosView(context)
                  : _buildVentasView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasView(BuildContext context) {
    final items = _ventasItems;
    if (items.isEmpty) {
      return const Center(child: Text('No hay movimientos'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
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
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.06),
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
          _VentaCardItem(:final ventaId, :final movimientos) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  _VentaCard(
                    key: ValueKey(ventaId),
                    ventaId: ventaId,
                    movimientos: movimientos,
                  ),
                  const Divider(),
                ],
              ),
            ),
        };
      },
    );
  }

  Widget _buildProductosView(BuildContext context) {
    final items = _productosItems;
    if (items.isEmpty) {
      return const Center(child: Text('No hay movimientos'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ProductoMovimientoCard(producto: p),
        );
      },
    );
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selected ? AppColors.primary : AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
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
    final notaLower = movimiento.nota?.toLowerCase() ?? '';
    final isPendingSale = !isEntrada &&
        (notaLower.contains('turno') ||
            notaLower.contains('pendiente') ||
            notaLower.contains('ajust') ||
            notaLower.contains('reducc') ||
            movimiento.cantidad < 0);
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
                          : (isPendingSale
                              ? 'Venta (Pendiente)'
                              : movimiento.tipo.label);
                      final suffix =
                          movimiento.cantidad < 0 ? ' (reducción)' : '';
                      return '$baseLabel \u00b7 $qty unidades$suffix';
                    })(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movimiento.tipo == MovimientoTipo.entrada
                        ? '${compactDateFormatter.format(movimiento.fecha)} ${timeFormatter.format(movimiento.fecha)}'
                        : '${movimiento.usuarioNombre} \u00b7 ${compactDateFormatter.format(movimiento.fecha)} ${timeFormatter.format(movimiento.fecha)}',
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

class _UsuarioAvatar extends StatelessWidget {
  const _UsuarioAvatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    const cacheSize = 160;
    final image = url.startsWith('http')
        ? ResizeImage(NetworkImage(url), width: cacheSize, height: cacheSize)
        : ResizeImage(FileImage(File(url)), width: cacheSize, height: cacheSize)
            as ImageProvider;
    return CircleAvatar(radius: 20, backgroundImage: image);
  }
}

class _VentaCard extends StatelessWidget {
  const _VentaCard({
    super.key,
    required this.ventaId,
    required this.movimientos,
  });

  final String ventaId;
  final List<Movimiento> movimientos;

  @override
  Widget build(BuildContext context) {
    if (movimientos.isEmpty) return const SizedBox.shrink();

    final first = movimientos.first;
    final totalUnits = movimientos.fold(0, (sum, m) => sum + m.cantidad.abs());

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.shopping_cart_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          title: Text(
            'Venta (POS)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '$totalUnits unidades',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${first.usuarioNombre} \u00b7 ${compactDateFormatter.format(first.fecha)} ${timeFormatter.format(first.fecha)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            for (final m in movimientos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${m.cantidad.abs()}x ${m.productoNombre}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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

class _ProductoMovimientoCard extends StatelessWidget {
  const _ProductoMovimientoCard({required this.producto});

  final _ProductoAgrupado producto;

  @override
  Widget build(BuildContext context) {
    final totalEntradas = producto.movimientos
        .where((m) => m.tipo == MovimientoTipo.entrada)
        .fold(0, (s, m) => s + m.cantidad.abs());
    final totalSalidas = producto.movimientos
        .where((m) => m.tipo == MovimientoTipo.salida)
        .fold(0, (s, m) => s + m.cantidad.abs());

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            producto.productoNombre,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${producto.totalUnidades} unidades',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (totalEntradas > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      '+$totalEntradas',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (totalSalidas > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '-$totalSalidas',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${producto.movimientos.length} ${producto.movimientos.length == 1 ? 'movimiento' : 'movimientos'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            for (final m in producto.movimientos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: m.tipo == MovimientoTipo.entrada
                            ? AppColors.success
                            : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${m.cantidad.abs()}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m.tipo == MovimientoTipo.entrada ? 'Entrada' : 'Salida',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: m.tipo == MovimientoTipo.entrada
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ),
                    Text(
                      '${compactDateFormatter.format(m.fecha)} ${timeFormatter.format(m.fecha)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      m.usuarioNombre,
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

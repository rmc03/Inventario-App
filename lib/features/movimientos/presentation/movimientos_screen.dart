import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/movimiento.dart';
import '../data/movimiento_repository.dart';
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
  _ProductoAgrupado({
    required this.productoId,
    required this.productoNombre,
    required this.totalEntradas,
    required this.totalSalidas,
    required this.movimientos,
  });

  final String productoId;
  final String productoNombre;
  final int totalEntradas;
  final int totalSalidas;
  final List<Movimiento> movimientos;

  int get neto => totalEntradas - totalSalidas;
  Movimiento get ultimoMovimiento => movimientos.first;
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
    final entradas = m.tipo == MovimientoTipo.entrada ? m.cantidad.abs() : 0;
    final salidas = m.tipo == MovimientoTipo.salida ? m.cantidad.abs() : 0;
    final existing = map[m.productoId];
    if (existing != null) {
      map[m.productoId] = _ProductoAgrupado(
        productoId: m.productoId,
        productoNombre: m.productoNombre,
        totalEntradas: existing.totalEntradas + entradas,
        totalSalidas: existing.totalSalidas + salidas,
        movimientos: [...existing.movimientos, m],
      );
    } else {
      map[m.productoId] = _ProductoAgrupado(
        productoId: m.productoId,
        productoNombre: m.productoNombre,
        totalEntradas: entradas,
        totalSalidas: salidas,
        movimientos: [m],
      );
    }
  }
  final result = map.values.toList();
  for (final p in result) {
    p.movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
  }
  // Ordenar por fecha del último movimiento (desc) para que el agrupamiento
  // visual por día quede contiguo.
  result.sort(
    (a, b) => b.ultimoMovimiento.fecha.compareTo(a.ultimoMovimiento.fecha),
  );
  return result;
}

class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
  bool _mostrarProductos = true;

  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(movimientosFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(movimientosFilterProvider.notifier).setQuery(value);
    });
  }

  void _limpiarFiltros() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(movimientosFilterProvider.notifier).limpiar();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => _FilterSheetContent(onLimpiar: _limpiarFiltros),
    );
  }

  String _rangoLabel(MovimientosFilterState f) {
    final inicio = compactDateFormatter.format(f.fechaInicio);
    final fin = compactDateFormatter.format(
      f.fechaFin.subtract(const Duration(days: 1)),
    );
    return switch (f.rango) {
      RangoFechaFiltro.hoy => 'Hoy',
      RangoFechaFiltro.semana => 'Esta semana ($inicio–$fin)',
      RangoFechaFiltro.mes => 'Últimos 30 días ($inicio–$fin)',
      RangoFechaFiltro.personalizado => 'Del $inicio al $fin',
    };
  }

  String _dateHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Hoy';
    if (day == yesterday) return 'Ayer';
    return compactDateFormatter.format(day);
  }

  Widget _dayHeaderWidget(BuildContext context, DateTime day) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No hay movimientos en este rango',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(movimientosFilterProvider);
    final source = ref.watch(movimientosFiltradosProvider);

    final productosItems = _agruparPorProducto(source);
    final ventasItems = _buildFlatItems(source);

    final hayChipsFiltro = filtro.tipo != TipoMovimientoFiltro.todos ||
        filtro.rango != RangoFechaFiltro.hoy;

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── Toggle de vista ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    0,
                  ),
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
                          onTap: () =>
                              setState(() => _mostrarProductos = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Búsqueda (debounce 350ms) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Buscar producto o dependiente...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.pillBorder,
                              borderSide: BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadii.pillBorder,
                              borderSide: BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadii.pillBorder,
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed: () => _showFilterSheet(context),
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: 'Filtrar',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Chips de filtros activos ──
                if (hayChipsFiltro)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      0,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (filtro.tipo != TipoMovimientoFiltro.todos)
                            InputChip(
                              label: Text(
                                filtro.tipo == TipoMovimientoFiltro.entradas
                                    ? 'Entradas'
                                    : 'Salidas',
                              ),
                              onDeleted: () => ref
                                  .read(movimientosFilterProvider.notifier)
                                  .setTipo(TipoMovimientoFiltro.todos),
                            ),
                          if (filtro.tipo != TipoMovimientoFiltro.todos &&
                              filtro.rango != RangoFechaFiltro.hoy)
                            const SizedBox(width: AppSpacing.sm),
                          if (filtro.rango != RangoFechaFiltro.hoy)
                            InputChip(
                              label: Text(_rangoLabel(filtro)),
                              onDeleted: () => ref
                                  .read(movimientosFilterProvider.notifier)
                                  .setRango(RangoFechaFiltro.hoy),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),

                // ── Contenido ──
                Expanded(
                  child: _mostrarProductos
                      ? _buildProductosView(context, productosItems)
                      : _buildVentasView(context, ventasItems),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVentasView(
    BuildContext context,
    List<_MovimientoItem> items,
  ) {
    if (items.isEmpty) return _emptyState(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return switch (item) {
          _DayHeaderItem(:final day) => _dayHeaderWidget(context, day),
          _MovimientoCardItem(:final movimiento) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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

  Widget _buildProductosView(
    BuildContext context,
    List<_ProductoAgrupado> productos,
  ) {
    if (productos.isEmpty) return _emptyState(context);

    DateTime? currentDay;
    final children = <Widget>[];
    for (final p in productos) {
      final m = p.ultimoMovimiento;
      final day = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      if (currentDay == null ||
          day.year != currentDay.year ||
          day.month != currentDay.month ||
          day.day != currentDay.day) {
        children.add(_dayHeaderWidget(context, day));
        currentDay = day;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: 10,
          ),
          child: _ProductoMovimientoCard(producto: p),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: children,
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
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter text button ────────────────────────────────────────────────────

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
                '$totalUnits ${pluralize('unidad', 'unidades', totalUnits)}',
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

  Color _netoColor(BuildContext context) {
    if (producto.neto > 0) return AppColors.success;
    if (producto.neto < 0) return AppColors.danger;
    return AppColors.muted;
  }

  IconData _netoIcon() {
    if (producto.neto > 0) return Icons.trending_up_rounded;
    if (producto.neto < 0) return Icons.trending_down_rounded;
    return Icons.remove_rounded;
  }

  String _breakdown(BuildContext context) {
    final entradas = producto.totalEntradas;
    final salidas = producto.totalSalidas;
    if (entradas > 0 && salidas > 0) {
      return '↓ $entradas ${pluralize('entrada', 'entradas', entradas)} \u00b7 '
          '↑ $salidas ${pluralize('salida', 'salidas', salidas)}';
    }
    if (entradas > 0) {
      return '+$entradas ${pluralize('unidad', 'unidades', entradas)}';
    }
    if (salidas > 0) {
      return '-$salidas ${pluralize('unidad', 'unidades', salidas)}';
    }
    return '0 ${pluralize('unidad', 'unidades', 0)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _netoColor(context);
    final ultimo = producto.ultimoMovimiento;

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
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _netoIcon(),
              color: color,
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
                  Icon(_netoIcon(), color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _breakdown(context),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${producto.movimientos.length} '
                '${pluralize('movimiento', 'movimientos', producto.movimientos.length)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Último \u00b7 ${ultimo.usuarioNombre} \u00b7 '
                '${compactDateFormatter.format(ultimo.fecha)} '
                '${timeFormatter.format(ultimo.fecha)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
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

// ─── Filter bottom sheet (estilo Inventario) ─────────────────────────────────

class _FilterSheetContent extends ConsumerStatefulWidget {
  const _FilterSheetContent({required this.onLimpiar});

  final VoidCallback onLimpiar;

  @override
  ConsumerState<_FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  final _sheetController = DraggableScrollableController();
  bool _isDragging = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarRangoPersonalizado() async {
    final filtro = ref.read(movimientosFilterProvider);
    final initial = filtro.rango == RangoFechaFiltro.personalizado &&
            filtro.fechaInicioCustom != null &&
            filtro.fechaFinCustom != null
        ? DateTimeRange(
            start: filtro.fechaInicioCustom!,
            end: filtro.fechaFinCustom!,
          )
        : DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
      locale: const Locale('es'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    // Si cancela o no completa el rango, se mantiene el filtro anterior
    // activo (no se dispara ninguna query nueva).
    if (picked != null && mounted) {
      ref
          .read(movimientosFilterProvider.notifier)
          .setRangoPersonalizado(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final filtro = ref.watch(movimientosFilterProvider);
        final notifier = ref.read(movimientosFilterProvider.notifier);
        return SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onVerticalDragStart: (_) => setState(() => _isDragging = true),
                onVerticalDragUpdate: (details) {
                  final delta = -details.primaryDelta! /
                      MediaQuery.of(context).size.height;
                  _sheetController.jumpTo(
                    (_sheetController.size + delta).clamp(0.35, 0.95),
                  );
                },
                onVerticalDragEnd: (_) =>
                    setState(() => _isDragging = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _isDragging ? AppColors.primary : AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtrar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Tipo de movimiento',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RadioTile(
                        label: 'Todos',
                        selected: filtro.tipo == TipoMovimientoFiltro.todos,
                        onTap: () =>
                            notifier.setTipo(TipoMovimientoFiltro.todos),
                      ),
                      _RadioTile(
                        label: 'Entradas',
                        selected:
                            filtro.tipo == TipoMovimientoFiltro.entradas,
                        onTap: () =>
                            notifier.setTipo(TipoMovimientoFiltro.entradas),
                      ),
                      _RadioTile(
                        label: 'Salidas',
                        selected: filtro.tipo == TipoMovimientoFiltro.salidas,
                        onTap: () =>
                            notifier.setTipo(TipoMovimientoFiltro.salidas),
                      ),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Rango de fecha',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RadioTile(
                        label: 'Hoy',
                        selected: filtro.rango == RangoFechaFiltro.hoy,
                        onTap: () => notifier.setRango(RangoFechaFiltro.hoy),
                      ),
                      _RadioTile(
                        label: 'Semana',
                        selected: filtro.rango == RangoFechaFiltro.semana,
                        onTap: () => notifier.setRango(RangoFechaFiltro.semana),
                      ),
                      _RadioTile(
                        label: 'Mes',
                        selected: filtro.rango == RangoFechaFiltro.mes,
                        onTap: () => notifier.setRango(RangoFechaFiltro.mes),
                      ),
                      _RadioTile(
                        label: 'Personalizado',
                        selected:
                            filtro.rango == RangoFechaFiltro.personalizado,
                        onTap: _seleccionarRangoPersonalizado,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onLimpiar,
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Limpiar filtros'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.primary : null,
      ),
      onTap: onTap,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/widgets/movimiento_filter_sheet.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../../ventas/providers/venta_provider.dart';
import '../data/movimiento_repository.dart';
import '../providers/movimiento_provider.dart';

/// Item unificado para el feed único (sin pestañas).
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
  const _VentaCardItem(this.ventaId, this.movimientos, {this.matchedProduct});
  final String ventaId;
  final List<Movimiento> movimientos;
  final String? matchedProduct;
}

/// Construye la lista plana de items (headers de día + cards individuales/agrupadas).
/// Incluye lógica de búsqueda profunda: si el query coincide con un producto dentro
/// de una venta, la venta aparece con un indicador de "Coincide con: ...".
List<_MovimientoItem> _buildFeedItems(
  List<Movimiento> movimientos,
  String searchQuery,
) {
  final q = searchQuery.trim().toLowerCase();
  final Map<DateTime, List<Movimiento>> grouped = {};
  
  for (final m in movimientos) {
    final day = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
    grouped.putIfAbsent(day, () => []).add(m);
  }
  
  final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a)); // Días: más reciente primero

  final List<_MovimientoItem> items = [];
  
  for (final day in days) {
    final dayList = grouped[day]!..sort((a, b) => b.fecha.compareTo(a.fecha)); // Dentro del día: más reciente primero (para reverse)

    final processedSales = <String>{};
    
    for (final m in dayList) {
      // Agrupar ventas por ventaId (tanto salidas antiguas como nuevas ventas)
      if ((m.tipo == MovimientoTipo.salida || m.tipo == MovimientoTipo.venta) && m.ventaId != null) {
        if (!processedSales.contains(m.ventaId!)) {
          processedSales.add(m.ventaId!);
          final saleItems = dayList
              .where((x) => x.ventaId == m.ventaId)
              .toList();
          
          // Búsqueda profunda: verificar si algún producto de la venta coincide
          String? matchedProduct;
          if (q.isNotEmpty) {
            for (final item in saleItems) {
              if (item.productoNombre.toLowerCase().contains(q)) {
                matchedProduct = item.productoNombre;
                break;
              }
            }
            // También buscar en productosVendidos si existe
            if (matchedProduct == null && m.productosVendidos != null) {
              for (final producto in m.productosVendidos!) {
                if (producto.toLowerCase().contains(q)) {
                  matchedProduct = producto;
                  break;
                }
              }
            }
          }
          
          items.add(_VentaCardItem(m.ventaId!, saleItems, matchedProduct: matchedProduct));
        }
      } else if (m.tipo != MovimientoTipo.salida && m.tipo != MovimientoTipo.venta) {
        // Movimientos individuales (Entradas, Altas, Inicio Turno, Producto Eliminado)
        items.add(_MovimientoCardItem(m));
      }
    }

    items.add(_DayHeaderItem(day));
  }
  
  return items;
}

class MovimientosScreen extends ConsumerStatefulWidget {
  const MovimientosScreen({super.key});

  @override
  ConsumerState<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends ConsumerState<MovimientosScreen> {
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
    final filtro = ref.read(movimientosFilterProvider);
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => MovimientoFilterSheet(
        initialTipo: filtro.tipo,
        initialRango: filtro.rango,
        initialFechaInicio: filtro.fechaInicioCustom,
        initialFechaFin: filtro.fechaFinCustom,
        onApply: ({
          required tipo,
          required rango,
          fechaInicio,
          fechaFin,
        }) {
          // Aplicar filtro de tipo
          ref.read(movimientosFilterProvider.notifier).setTipo(tipo);
          
          // Aplicar filtro de rango de fecha
          if (rango == RangoFechaFiltro.personalizado) {
            // Solo aplicar si las fechas son válidas
            if (fechaInicio != null && fechaFin != null) {
              ref.read(movimientosFilterProvider.notifier).setRangoPersonalizado(
                    fechaInicio,
                    fechaFin,
                  );
            }
          } else {
            ref.read(movimientosFilterProvider.notifier).setRango(rango);
          }
        },
      ),
    );
  }

  String _rangoLabel(MovimientosFilterState f) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    String formatCompact(DateTime date) {
      return '${date.day} ${months[date.month - 1]}';
    }
    
    switch (f.rango) {
      case RangoFechaFiltro.hoy:
        return 'Hoy';
      case RangoFechaFiltro.semana:
        final inicio = formatCompact(f.fechaInicio);
        final fin = formatCompact(f.fechaFin.subtract(const Duration(days: 1)));
        return 'Esta semana ($inicio - $fin)';
      case RangoFechaFiltro.mes:
        final inicio = formatCompact(f.fechaInicio);
        final fin = formatCompact(f.fechaFin.subtract(const Duration(days: 1)));
        return 'Últimos 30 días ($inicio - $fin)';
      case RangoFechaFiltro.personalizado:
        final inicio = formatCompact(f.fechaInicio);
        final fin = formatCompact(f.fechaFin.subtract(const Duration(days: 1)));
        return 'Del $inicio al $fin';
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
    final filtro = ref.watch(movimientosFilterProvider);
    final source = ref.watch(movimientosFiltradosProvider);
    final items = _buildFeedItems(source, filtro.query);

    final hayFiltrosActivos = filtro.tipo != TipoMovimientoFiltro.todos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
              ScreenMenuItem(
                value: 'exportar',
                icon: Icons.file_download_outlined,
                iconColor: context.colors.success,
                title: 'Exportar movimientos',
                subtitle: 'Exportar a archivo',
                enabled: false,
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/admin/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                
                // ── Barra de búsqueda + botón filtrar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Buscar producto o dependiente...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: filtro.query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(movimientosFilterProvider.notifier)
                                          .setQuery('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.pillBorder,
                              borderSide: BorderSide(color: context.colors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadii.pillBorder,
                              borderSide: BorderSide(color: context.colors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadii.pillBorder,
                              borderSide: BorderSide(
                                color: context.colors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed: () => _showFilterSheet(context),
                        icon: Badge(
                          isLabelVisible: hayFiltrosActivos,
                          child: const Icon(Icons.tune_rounded),
                        ),
                        tooltip: 'Filtrar',
                      ),
                    ],
                  ),
                ),
                
                // ── Chip del rango activo (solo mostrar si NO es "Hoy") ──
                if (filtro.rango != RangoFechaFiltro.hoy)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: context.colors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mostrando: ${_rangoLabel(filtro)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.colors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                
                // ── Chips de filtros activos (tipo) ──
                if (filtro.tipo != TipoMovimientoFiltro.todos)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xs,
                      AppSpacing.xl,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        avatar: Icon(
                          switch (filtro.tipo) {
                            TipoMovimientoFiltro.entradas => Icons.arrow_forward_rounded,
                            TipoMovimientoFiltro.salidas => Icons.arrow_back_rounded,
                            TipoMovimientoFiltro.ventas => Icons.shopping_cart_rounded,
                            TipoMovimientoFiltro.inicioTurno => Icons.login_rounded,
                            TipoMovimientoFiltro.eliminados => Icons.delete_outline_rounded,
                            _ => Icons.filter_list_rounded,
                          },
                          size: 18,
                        ),
                        label: Text(
                          switch (filtro.tipo) {
                            TipoMovimientoFiltro.entradas => 'Solo Entradas',
                            TipoMovimientoFiltro.salidas => 'Solo Disminuciones',
                            TipoMovimientoFiltro.ventas => 'Solo Ventas',
                            TipoMovimientoFiltro.inicioTurno => 'Solo Inicios de Turno',
                            TipoMovimientoFiltro.eliminados => 'Solo Eliminados',
                            _ => 'Filtrado',
                          },
                        ),
                        onDeleted: () => ref
                            .read(movimientosFilterProvider.notifier)
                            .setTipo(TipoMovimientoFiltro.todos),
                      ),
                    ),
                  ),
                
                const SizedBox(height: AppSpacing.md),

                // ── Feed único ──
                Expanded(
                  child: items.isEmpty
                      ? _EmptyState(onLimpiar: _limpiarFiltros)
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xl,
                            bottom: AppSpacing.xl,
                          ),
                          reverse: true, // Estilo WhatsApp: mensajes recientes abajo
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index]; // Mantener orden original (más reciente al final)
                            return switch (item) {
                              _DayHeaderItem(:final day) => _DayHeader(
                                  day: day,
                                  label: _dateHeader(day),
                                ),
                              _MovimientoCardItem(:final movimiento) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                  ),
                                  child: Column(
                                    children: [
                                      _MovimientoCard(
                                        key: ValueKey(movimiento.id),
                                        movimiento: movimiento,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],
                                  ),
                                ),
                              _VentaCardItem(
                                :final ventaId,
                                :final movimientos,
                                :final matchedProduct,
                              ) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                  ),
                                  child: Column(
                                    children: [
                                      _VentaCard(
                                        key: ValueKey(ventaId),
                                        ventaId: ventaId,
                                        movimientos: movimientos,
                                        matchedProduct: matchedProduct,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],
                                  ),
                                ),
                            };
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Subwidgets
// ═══════════════════════════════════════════════════════════════════════════

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.label});
  
  final DateTime day;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: context.colors.line.withValues(alpha: 0.4),
              thickness: 1,
              endIndent: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.withValues(alpha: 0.08),
                  context.colors.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: context.colors.line.withValues(alpha: 0.4),
              thickness: 1,
              indent: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLimpiar});
  
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono con diseño mejorado
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.08),
                    context.colors.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: context.colors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No hay movimientos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Los movimientos de inventario\naparecerán aquí',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.colors.muted,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onLimpiar,
              icon: const Icon(Icons.filter_list_off_rounded),
              label: const Text('Limpiar filtros'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card individual para movimientos de Entrada, Alta, Inicio de Turno y Producto Eliminado.
class _MovimientoCard extends StatelessWidget {
  const _MovimientoCard({super.key, required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    return switch (movimiento.tipo) {
      MovimientoTipo.entrada => _buildEntradaCard(context),
      MovimientoTipo.salida => const SizedBox.shrink(), // Las salidas individuales ya no se usan (solo ventas con ventaId)
      MovimientoTipo.inicioTurno => _buildInicioTurnoCard(context),
      MovimientoTipo.productoEliminado => _buildProductoEliminadoCard(context),
      MovimientoTipo.venta => const SizedBox.shrink(), // Las ventas se manejan en _VentaCard
    };
  }

  /// 🔵 Entrada de producto (flecha azul →) | 🟠 Ajuste manual negativo
  Widget _buildEntradaCard(BuildContext context) {
    // Determinar si es un ajuste manual de disminución (entrada negativa)
    final esAjusteNegativo = movimiento.cantidad < 0;
    final esAlta = !esAjusteNegativo && 
        (movimiento.nota?.toLowerCase().contains('alta') ?? false);
    
    // 🔵 Azul = Entrada positiva | 🟠 Naranja = Ajuste negativo | ⚪ Gris = Alta
    final Color color;
    final IconData icon;
    final String label;
    
    if (esAjusteNegativo) {
      color = context.colors.warning;
      icon = Icons.trending_down_rounded;
      label = 'Ajuste manual';
    } else if (esAlta) {
      color = context.colors.muted;
      icon = Icons.add_circle_outline_rounded;
      label = 'Alta de producto';
    } else {
      color = context.colors.info;
      icon = Icons.trending_up_rounded;
      label = 'Entrada de producto';
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimiento.productoNombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormatter.format(movimiento.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.colors.muted.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${esAjusteNegativo ? '' : '+'}${movimiento.cantidad} ${movimiento.cantidad.abs() == 1 ? 'unidad' : 'unidades'}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (movimiento.nota != null && !esAlta) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.muted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 14,
                            color: context.colors.muted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              movimiento.nota!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// 🟢 Inicio de turno (verde)
  Widget _buildInicioTurnoCard(BuildContext context) {
    final color = context.colors.success;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.login_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inicio de turno',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormatter.format(movimiento.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          movimiento.usuarioNombre,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
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

  /// 🔴 Producto eliminado (rojo con basura)
  Widget _buildProductoEliminadoCard(BuildContext context) {
    final color = context.colors.danger;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.delete_outline_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimiento.productoNombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormatter.format(movimiento.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.colors.muted.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Producto eliminado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                    ],
                  ),
                  if (movimiento.cantidad > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Stock: ${movimiento.cantidad} ${movimiento.cantidad == 1 ? 'unidad' : 'unidades'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (movimiento.nota != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Motivo: ${movimiento.nota!}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: color,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Card agrupada para Ventas con detalles expandibles.
/// Muestra un resumen y al tocar la flecha se expanden los productos vendidos.
class _VentaCard extends ConsumerStatefulWidget {
  const _VentaCard({
    super.key,
    required this.ventaId,
    required this.movimientos,
    this.matchedProduct,
  });

  final String ventaId;
  final List<Movimiento> movimientos;
  final String? matchedProduct;

  @override
  ConsumerState<_VentaCard> createState() => _VentaCardState();
}

class _VentaCardState extends ConsumerState<_VentaCard> with SingleTickerProviderStateMixin {
  bool _expandido = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _expansionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 grados (0.5 * π)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _expansionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _expandido = !_expandido;
      if (_expandido) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movimientos.isEmpty) return const SizedBox.shrink();

    final first = widget.movimientos.first;
    
    // Calcular totales desde los movimientos
    final totalUnits = widget.movimientos.fold(0, (sum, m) => sum + m.cantidad.abs());
    final totalAmount = first.totalVenta ?? widget.movimientos.fold<double>(
      0.0,
      (sum, m) => sum + ((m.precioUnitario ?? 0) * m.cantidad.abs()),
    );

    // 🔵 Azul primario = Venta (la acción principal del negocio)
    final color = context.colors.primary;

    // Buscar la venta en el turno actual
    final ventas = ref.read(ventasDelTurnoProvider);
    final venta = ventas.where((v) => v.id == widget.ventaId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Card principal (toca para ver detalles de la venta) ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: venta != null
                  ? () => context.push('/dependiente/turno/venta/${venta.id}', extra: venta)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono animado
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: _expandido ? 0.15 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Contenido
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Venta',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              // Botón de flecha (intercepta tap para expandir/colapsar)
                              GestureDetector(
                                onTap: () {
                                  _toggleExpansion();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOutCubic,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _expandido 
                                        ? color.withValues(alpha: 0.12)
                                        : context.colors.muted.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: RotationTransition(
                                    turns: _rotationAnimation,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _expandido ? color : context.colors.muted,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: context.colors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeFormatter.format(first.fecha),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colors.muted,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: context.colors.muted.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: context.colors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  first.usuarioNombre,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.colors.muted,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Badge de unidades
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.colors.info.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 14,
                                      color: context.colors.info,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$totalUnits ${totalUnits == 1 ? 'ud' : 'uds'}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: context.colors.info,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge de monto
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.colors.success.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_money_rounded,
                                      size: 16,
                                      color: context.colors.success,
                                    ),
                                    Text(
                                      formatCurrency(totalAmount).replaceAll('\$', ''),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: context.colors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ── Submenú expandible con animación (solo vista rápida) ──
          SizeTransition(
            sizeFactor: _expansionAnimation,
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surfaceSecondary,
                border: Border(
                  top: BorderSide(
                    color: context.colors.line.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 14,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Productos vendidos',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: context.colors.ink,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Lista de productos desde productosVendidos o desde los movimientos
                    if (first.productosVendidos != null)
                      ...first.productosVendidos!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final producto = entry.value;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    producto,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      ...widget.movimientos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final mov = entry.value;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${mov.cantidad}x ${mov.productoNombre}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                if (mov.precioUnitario != null)
                                  Text(
                                    formatCurrency((mov.precioUnitario! * mov.cantidad).toDouble()),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.success,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
          
          // Indicador de coincidencia (búsqueda profunda)
          if (widget.matchedProduct != null && !_expandido) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: context.colors.warning.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.colors.warning.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: context.colors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coincide con: ${widget.matchedProduct}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
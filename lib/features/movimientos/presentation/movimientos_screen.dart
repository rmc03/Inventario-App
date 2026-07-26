import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/pago.dart';
import '../../../shared/models/venta.dart';
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
  const _VentaCardItem(this.ventaId, this.movimientos, {this.matchedProduct, this.venta});
  final String ventaId;
  final List<Movimiento> movimientos;
  final String? matchedProduct;
  final Venta? venta;
}

/// Construye la lista plana de items (headers de día + cards individuales/agrupadas).
/// Incluye lógica de búsqueda profunda: si el query coincide con un producto dentro
/// de una venta, la venta aparece con un indicador de "Coincide con: ...".
List<_MovimientoItem> _buildFeedItems(
  List<Movimiento> movimientos,
  String searchQuery,
  List<Venta> ventas,
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
          
          final venta = ventas.where((v) => v.id == m.ventaId).firstOrNull;
          items.add(_VentaCardItem(m.ventaId!, saleItems, matchedProduct: matchedProduct, venta: venta));
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
          ref.read(movimientosFilterProvider.notifier).setTipo(tipo);
          if (rango == RangoFechaFiltro.personalizado) {
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
      case RangoFechaFiltro.todos:
        return 'Todos';
      case RangoFechaFiltro.hoy:
        return 'Hoy';
      case RangoFechaFiltro.semana:
        final inicio = formatCompact(f.fechaInicio!);
        final fin = formatCompact(f.fechaFin!.subtract(const Duration(days: 1)));
        return 'Esta semana ($inicio - $fin)';
      case RangoFechaFiltro.mes:
        final inicio = formatCompact(f.fechaInicio!);
        final fin = formatCompact(f.fechaFin!.subtract(const Duration(days: 1)));
        return 'Últimos 30 días ($inicio - $fin)';
      case RangoFechaFiltro.personalizado:
        final inicio = formatCompact(f.fechaInicio!);
        final fin = formatCompact(f.fechaFin!.subtract(const Duration(days: 1)));
        return 'Del $inicio al $fin)';
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
    final ventas = ref.watch(ventasDelTurnoProvider);
    final items = _buildFeedItems(source, filtro.query, ventas);

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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.pillBorder,
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.primary.withValues(alpha: filtro.query.isNotEmpty ? 0.08 : 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar producto o dependiente...',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: context.colors.muted,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 24,
                                color: filtro.query.isNotEmpty 
                                    ? context.colors.primary 
                                    : context.colors.muted,
                              ),
                              suffixIcon: filtro.query.isNotEmpty
                                  ? _AnimatedClearButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(movimientosFilterProvider.notifier)
                                            .setQuery('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: AppRadii.pillBorder,
                                borderSide: BorderSide(
                                  color: context.colors.line,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadii.pillBorder,
                                borderSide: BorderSide(
                                  color: context.colors.line,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadii.pillBorder,
                                borderSide: BorderSide(
                                  color: context.colors.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: context.colors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _AnimatedFilterButton(
                        isActive: hayFiltrosActivos,
                        onPressed: () => _showFilterSheet(context),
                      ),
                    ],
                  ),
                ),
                
                // ── Chip del rango activo (solo mostrar si NO es "Todos") ──
                if (filtro.rango != RangoFechaFiltro.todos)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colors.primary.withValues(alpha: 0.08),
                            context.colors.primary.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mostrando: ${_rangoLabel(filtro)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colors.primary.withValues(alpha: 0.12),
                              context.colors.primary.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.colors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              switch (filtro.tipo) {
                                TipoMovimientoFiltro.entradas => Icons.arrow_forward_rounded,
                                TipoMovimientoFiltro.salidas => Icons.arrow_back_rounded,
                                TipoMovimientoFiltro.ventas => Icons.shopping_cart_rounded,
                                TipoMovimientoFiltro.inicioTurno => Icons.login_rounded,
                                TipoMovimientoFiltro.eliminados => Icons.delete_rounded,
                                _ => Icons.filter_list_rounded,
                              },
                              size: 18,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              switch (filtro.tipo) {
                                TipoMovimientoFiltro.entradas => 'Solo Entradas',
                                TipoMovimientoFiltro.salidas => 'Solo Disminuciones',
                                TipoMovimientoFiltro.ventas => 'Solo Ventas',
                                TipoMovimientoFiltro.inicioTurno => 'Solo Inicios de Turno',
                                TipoMovimientoFiltro.eliminados => 'Solo Eliminados',
                                _ => 'Filtrado',
                              },
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.primary,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => ref
                                  .read(movimientosFilterProvider.notifier)
                                  .setTipo(TipoMovimientoFiltro.todos),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: context.colors.primary,
                              ),
                            ),
                          ],
                        ),
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
                            
                            // Animación de entrada sutil para cada item
                            return _AnimatedListItem(
                              index: index,
                              child: switch (item) {
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
                                  :final venta,
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
                                          venta: venta,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                      ],
                                    ),
                                  ),
                              },
                            );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.line.withValues(alpha: 0.0),
                    context.colors.line.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              // Fondo azul sólido en dark mode
              color: isDark ? context.colors.primary : null,
              gradient: isDark ? null : LinearGradient(
                colors: [
                  context.colors.primary.withValues(alpha: 0.16),
                  context.colors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: isDark ? null : Border.all(
                color: context.colors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
              // Sombra mínima y sutil
              boxShadow: isDark ? [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : context.colors.primary,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.line.withValues(alpha: 0.5),
                    context.colors.line.withValues(alpha: 0.0),
                  ],
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono simple sin excesivos brillos
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark ? [
                    context.colors.primary.withValues(alpha: 0.12),
                    context.colors.primary.withValues(alpha: 0.06),
                  ] : [
                    context.colors.primary.withValues(alpha: 0.14),
                    context.colors.primary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                // Sombra sutil, no exagerada
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 88,
                color: context.colors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No hay movimientos',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                    color: context.colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Los movimientos de inventario\naparecerán aquí',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    color: context.colors.muted,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
            FilledButton.icon(
              onPressed: onLimpiar,
              icon: const Icon(Icons.filter_list_off_rounded, size: 22),
              label: const Text('Limpiar filtros'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                elevation: 2,
                shadowColor: context.colors.primary.withValues(alpha: 0.3),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
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
    return Semantics(
      label: '${movimiento.tipo.label}: ${movimiento.productoNombre}, ${movimiento.cantidad.abs()} unidades',
      child: switch (movimiento.tipo) {
        MovimientoTipo.entrada => _buildEntradaCard(context),
        MovimientoTipo.salida => const SizedBox.shrink(), // Las salidas individuales ya no se usan (solo ventas con ventaId)
        MovimientoTipo.inicioTurno => _buildInicioTurnoCard(context),
        MovimientoTipo.productoEliminado => _buildProductoEliminadoCard(context),
        MovimientoTipo.venta => const SizedBox.shrink(), // Las ventas se manejan en _VentaCard
      },
    );
  }

  /// 🔵 Entrada de producto | 🟠 Ajuste manual negativo (reducción de stock)
  Widget _buildEntradaCard(BuildContext context) {
    // Determinar el tipo específico de movimiento
    final esAjusteNegativo = movimiento.cantidad < 0;
    final esAlta = !esAjusteNegativo && 
        (movimiento.nota?.toLowerCase().contains('alta') ?? false);
    
    // Configuración según tipo de acción
    final Color color;
    final IconData icon;
    final String accionTexto;
    
    if (esAjusteNegativo) {
      // 🟠 Naranja: Reducción de stock por ajuste manual
      color = context.colors.warning;
      icon = Icons.remove_circle_rounded;
      accionTexto = 'Reducidas ${movimiento.cantidad.abs()} ${movimiento.cantidad.abs() == 1 ? 'unidad' : 'unidades'} de ${movimiento.productoNombre}';
    } else if (esAlta) {
      // 🟢 Verde: Nueva adición al inventario
      color = context.colors.success;
      icon = Icons.add_circle_rounded;
      accionTexto = 'Añadidas ${movimiento.cantidad} ${movimiento.cantidad == 1 ? 'unidad' : 'unidades'} de ${movimiento.productoNombre}';
    } else {
      // 🟢 Verde: Entrada/reposición de stock
      color = context.colors.success;
      icon = Icons.add_circle_rounded;
      accionTexto = 'Añadidas ${movimiento.cantidad} ${movimiento.cantidad == 1 ? 'unidad' : 'unidades'} de ${movimiento.productoNombre}';
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accionTexto,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeFormatter.format(movimiento.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: context.colors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.muted.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          movimiento.usuarioNombre,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                color: context.colors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }


  /// Inicio/Cierre de turno (color neutral)
  Widget _buildInicioTurnoCard(BuildContext context) {
    // Color primary para acciones de turno
    final color = context.colors.primary;
    final esInicio = movimiento.nota?.toLowerCase().contains('inicio') ?? true;
    
    final accionTexto = esInicio 
        ? '${movimiento.usuarioNombre} inició turno'
        : '${movimiento.usuarioNombre} cerró turno';
    
    final icon = esInicio ? Icons.play_circle_rounded : Icons.pause_circle_rounded;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accionTexto,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeFormatter.format(movimiento.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: context.colors.muted,
                              fontWeight: FontWeight.w500,
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
    );
  }

  /// 🔴 Producto eliminado
  Widget _buildProductoEliminadoCard(BuildContext context) {
    final color = context.colors.danger;
    final cantidadTexto = movimiento.cantidad > 0 
        ? ' (${movimiento.cantidad} ${movimiento.cantidad == 1 ? 'unidad' : 'unidades'} en stock)'
        : '';
    
    final accionTexto = 'Eliminado: ${movimiento.productoNombre}$cantidadTexto';

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.delete_rounded, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accionTexto,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeFormatter.format(movimiento.fecha),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: context.colors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (movimiento.nota != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.colors.muted.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            movimiento.nota!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: context.colors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
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

/// Card agrupada para Ventas con detalles expandibles.
/// Muestra un resumen y al tocar la flecha se expanden los productos vendidos.
class _VentaCard extends ConsumerStatefulWidget {
  const _VentaCard({
    super.key,
    required this.ventaId,
    required this.movimientos,
    this.matchedProduct,
    this.venta,
  });

  final String ventaId;
  final List<Movimiento> movimientos;
  final String? matchedProduct;
  final Venta? venta;

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

    // 🟣 Morado/Primary: Color distintivo para ventas alineado con el tema de la app
    final color = context.colors.primary;

    final venta = widget.venta;

    return Semantics(
      label: 'Venta: $totalUnits unidades, ${formatCurrency(totalAmount)}',
      button: venta != null,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
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
              borderRadius: BorderRadius.circular(16),
              onTap: venta != null
                  ? () => context.push('/admin/movimientos/ventas/${venta.id}', extra: venta)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono animado
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _expandido 
                              ? [
                                  color.withValues(alpha: 0.22),
                                  color.withValues(alpha: 0.16),
                                ]
                              : [
                                  color.withValues(alpha: 0.18),
                                  color.withValues(alpha: 0.12),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: _expandido ? 0.35 : 0.25),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Contenido
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Venta de ${formatCurrency(totalAmount)}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
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
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _expandido 
                                        ? color.withValues(alpha: 0.15)
                                        : context.colors.muted.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: RotationTransition(
                                    turns: _rotationAnimation,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _expandido ? color : context.colors.muted,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: context.colors.muted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                timeFormatter.format(first.fecha),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      color: context.colors.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: context.colors.muted.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: context.colors.muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  first.usuarioNombre,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 13,
                                        color: context.colors.muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Chips de unidades y método de pago
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Badge de unidades
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.14),
                                      color.withValues(alpha: 0.10),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      size: 16,
                                      color: color,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      '$totalUnits ${totalUnits == 1 ? 'ud' : 'uds'}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 14,
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Chip de método de pago (si hay venta disponible)
                              if (venta != null && venta.pagos.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    // Detectar el método de pago (mixto si hay más de un tipo de pago)
                                    final MetodoPago metodoPago;
                                    if (venta.pagos.length > 1) {
                                      metodoPago = MetodoPago.mixto;
                                    } else {
                                      metodoPago = venta.pagos.first.metodo;
                                    }

                                    final chipColor = metodoPago == MetodoPago.efectivo
                                        ? context.colors.success
                                        : metodoPago == MetodoPago.transferencia
                                            ? context.colors.warning
                                            : context.colors.info;

                                    final chipIcon = metodoPago == MetodoPago.efectivo
                                        ? Icons.payments_rounded
                                        : metodoPago == MetodoPago.transferencia
                                            ? Icons.credit_card_rounded
                                            : Icons.sync_alt_rounded;

                                    final chipLabel = metodoPago == MetodoPago.efectivo
                                        ? 'Efectivo'
                                        : metodoPago == MetodoPago.transferencia
                                            ? 'Transferencia'
                                            : 'Mixto';

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            chipColor.withValues(alpha: 0.14),
                                            chipColor.withValues(alpha: 0.10),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: chipColor.withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            chipIcon,
                                            size: 16,
                                            color: chipColor,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            chipLabel,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontSize: 14,
                                                  color: chipColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
                          duration: Duration(milliseconds: 150 + (index * 30)),  // 🔥 Más rápido: 200+50 → 150+30
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
                          duration: Duration(milliseconds: 150 + (index * 30)),  // 🔥 Más rápido: 200+50 → 150+30
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
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Animated Widgets - Motion Layer
// ═══════════════════════════════════════════════════════════════════════════

/// Animated entrance for list items - gentle upward slide with fade.
/// Matches the reverse scroll direction (items settle from below).
class _AnimatedListItem extends StatefulWidget {
  const _AnimatedListItem({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Staggered delay based on index (cap at 10 items to avoid long waits)
    final delay = (widget.index.clamp(0, 10) * 30);
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),  // 🔥 Más rápido: 400 → 300
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15), // Gentle upward from below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation after delay
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated clear button with scale press feedback.
class _AnimatedClearButton extends StatefulWidget {
  const _AnimatedClearButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_AnimatedClearButton> createState() => _AnimatedClearButtonState();
}

class _AnimatedClearButtonState extends State<_AnimatedClearButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          Icons.clear_rounded,
          color: Theme.of(context).extension<AppColorsExtension>()?.muted,
        ),
      ),
    );
  }
}

/// Animated filter button with pulsing effect when active.
class _AnimatedFilterButton extends StatefulWidget {
  const _AnimatedFilterButton({
    required this.isActive,
    required this.onPressed,
  });

  final bool isActive;
  final VoidCallback onPressed;

  @override
  State<_AnimatedFilterButton> createState() => _AnimatedFilterButtonState();
}

class _AnimatedFilterButtonState extends State<_AnimatedFilterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedFilterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.15 * _pulseAnimation.value),
                      blurRadius: 12 * _pulseAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: IconButton.filledTonal(
            onPressed: widget.onPressed,
            icon: Badge(
              isLabelVisible: widget.isActive,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.tune_rounded,
                size: 24,
                color: widget.isActive ? colors.primary : colors.muted,
              ),
            ),
            tooltip: 'Filtrar',
            style: IconButton.styleFrom(
              backgroundColor: widget.isActive
                  ? colors.primary.withValues(alpha: 0.12)
                  : colors.surfaceSecondary,
              padding: const EdgeInsets.all(14),
            ),
          ),
        );
      },
    );
  }
}

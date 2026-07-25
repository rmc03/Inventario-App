import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/categoria.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/filter_sort_sheet.dart';
import '../providers/inventario_provider.dart';
import '../../movimientos/providers/movimiento_provider.dart';

final _emptyCategoria = Categoria(
  id: '',
  nombre: '',
  createdAt: DateTime.utc(2024),
);

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  Future<void> _onRefresh() async {
    await ref.read(inventarioControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioControllerProvider);
    final productos = state.productosFiltrados;

    final configPath = widget.isAdmin
        ? '/admin/configuracion'
        : '/dependiente/configuracion';

    final activeFilterCount = [
      state.categoriaId != null,
      state.soloStockBajo,
      state.sortBy != ProductoSortBy.nombreAsc,
    ].where((e) => e).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
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
                title: 'Exportar inventario',
                subtitle: 'Exportar a archivo',
                enabled: false,
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push(configPath);
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Haptics.tap(context);
                context.push('/admin/inventario/productos/nuevo');
              },
              tooltip: 'Crear producto',
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: context.colors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ─── Barra de búsqueda tipo pill ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: ref
                              .read(inventarioControllerProvider.notifier)
                              .setSearch,
                          decoration: InputDecoration(
                            hintText: 'Buscar producto...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: state.search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    onPressed: () => ref
                                        .read(inventarioControllerProvider.notifier)
                                        .setSearch(''),
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
                      Badge(
                        label: activeFilterCount > 0
                            ? Text('$activeFilterCount')
                            : null,
                        isLabelVisible: activeFilterCount > 0,
                        backgroundColor: context.colors.primary,
                        smallSize: 18,
                        child: IconButton.filledTonal(
                          onPressed: () => _showFilterSheet(context),
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Filtrar y Ordenar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── Chips de filtros activos ─────────────────────────────
              if (state.categoriaId != null ||
                  state.soloStockBajo ||
                  state.sortBy != ProductoSortBy.nombreAsc)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      0,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (state.categoriaId != null) ...[
                            InputChip(
                              label: Text(
                                state.categorias
                                    .firstWhere(
                                      (c) => c.id == state.categoriaId,
                                      orElse: () => _emptyCategoria,
                                    )
                                    .nombre,
                              ),
                              onDeleted: () => ref
                                  .read(inventarioControllerProvider.notifier)
                                  .setCategoria(null),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (state.soloStockBajo) ...[
                            InputChip(
                              label: const Text('Solo stock bajo'),
                              onDeleted: () => ref
                                  .read(inventarioControllerProvider.notifier)
                                  .setSoloStockBajo(false),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (state.sortBy != ProductoSortBy.nombreAsc) ...[
                            InputChip(
                              label: Text('Orden: ${state.sortBy.label}'),
                              onDeleted: () => ref
                                  .read(inventarioControllerProvider.notifier)
                                  .setSortBy(ProductoSortBy.nombreAsc),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              // ─── Stats (solo admin) ───────────────────────────────────
              if (widget.isAdmin)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      children: [
                        StatCard(
                          label: 'Total productos',
                          value: state.totalProductos.toString(),
                          tint: context.colors.primary,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        StatCard(
                          label: 'Valor total',
                          value: formatCurrency(state.valorTotal),
                          tint: context.colors.success,
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              // ─── Lista de productos ────────────────────────────────
              if (state.isLoading)
                SliverToBoxAdapter(
                  child: SkeletonList(
                    itemCount: 5,
                    showTrailing: true,
                  ),
                )
              else if (productos.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyInventory(
                    onCrearProducto: widget.isAdmin
                        ? () {
                            Haptics.tap(context);
                            context.push('/admin/inventario/productos/nuevo');
                          }
                        : null,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    return _AnimatedProductTile(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            _ProductTile(
                              key: ValueKey(producto.id),
                              producto: producto,
                              isAdmin: widget.isAdmin,
                            ),
                            const _ListSeparator(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final state = ref.read(inventarioControllerProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => FilterSortSheet(
        initialSortBy: state.sortBy,
        initialCategoriaId: state.categoriaId,
        initialSoloStockBajo: state.soloStockBajo,
        categorias: state.categorias,
        title: 'Ordenar y Filtrar',
        onApply: ({
          required sortBy,
          required categoriaId,
          required soloStockBajo,
        }) {
          final notifier = ref.read(inventarioControllerProvider.notifier);
          notifier.setSortBy(sortBy);
          notifier.setCategoria(categoriaId);
          notifier.setSoloStockBajo(soloStockBajo);
        },
      ),
    );
  }
}

// ─── Tile con animación de entrada escalonada ───────────────────────────────

class _AnimatedProductTile extends StatefulWidget {
  const _AnimatedProductTile({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedProductTile> createState() => _AnimatedProductTileState();
}

class _AnimatedProductTileState extends State<_AnimatedProductTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Delay escalonado: 60ms por índice, máximo 600ms
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 600));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
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
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ─── Tile de producto estilo iOS ─────────────────────────────────────────────

class _ProductTile extends ConsumerWidget {
  const _ProductTile({
    super.key,
    required this.producto,
    required this.isAdmin,
  });

  final Producto producto;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = RepaintBoundary(
      child: Semantics(
        label: '${producto.nombre}, ${formatCurrency(producto.precio)}, ${producto.stockActual} unidades${producto.tieneStockBajo ? ', stock bajo' : ''}',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final path = isAdmin
                  ? '/admin/inventario/productos/${producto.id}'
                  : '/dependiente/inventario/productos/${producto.id}';
              context.push(path);
            },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'product-photo-${producto.id}',
                  child: ProductPhoto(url: producto.fotoUrl, size: 64),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                        children: [
                          Text(
                            '${producto.stockActual} uds.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Builder(
                            builder: (context) {
                              final sold = ref.watch(
                                currentCuadreSalesProvider.select(
                                  (sales) => sales[producto.id] ?? 0,
                                ),
                              );
                              if (sold > 0) {
                                final soldLabel = sold == 1
                                    ? '1 vendido hoy'
                                    : '$sold vendidos hoy';
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: EdgeInsets.only(
                                    left: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.warning.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    soldLabel,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: context.colors.warning),
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),
                          if (producto.tieneStockBajo) ...[
                            SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: context.colors.danger,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Stock bajo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: context.colors.danger,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
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
                SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(producto.precio),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (isAdmin)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.colors.muted,
                        size: 22,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );

    if (!isAdmin) return tile;

    return Dismissible(
      key: ValueKey('dismiss-${producto.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        Haptics.tap(context);
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: context.colors.danger,
              size: 42,
            ),
            title: const Text('¿Eliminar producto?'),
            content: Text(
              '¿Deseas eliminar "${producto.nombre}"? Esta acción no se puede deshacer.',
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Haptics.warning(context);
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.danger,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(inventarioControllerProvider.notifier)
            .deleteProducto(producto.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.colors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: tile,
    );
  }
}

/// Separador fino estilo iOS (0.33pt con padding horizontal).
class _ListSeparator extends StatelessWidget {
  const _ListSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Divider(height: 1, indent: 72),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({this.onCrearProducto});

  final VoidCallback? onCrearProducto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
        shadows: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sin productos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ajusta la búsqueda o crea un producto nuevo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onCrearProducto != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onCrearProducto,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Crear producto'),
                style: FilledButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/filter_sort_sheet.dart';
import '../providers/inventario_provider.dart';
import '../../movimientos/providers/movimiento_provider.dart';

final _emptyCategoria = Categoria(
  id: '',
  nombre: '',
  createdAt: DateTime.utc(2024),
);

class InventarioScreen extends ConsumerWidget {
  const InventarioScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventarioControllerProvider);
    final productos = state.productosFiltrados;

    final configPath = isAdmin ? '/admin/configuracion' : '/dependiente/configuracion';

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
      floatingActionButton: isAdmin
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
        child: CustomScrollView(
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
                          prefixIcon: Icon(Icons.search_rounded),
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
                      onPressed: () => _showFilterSheet(context, ref),
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'Filtrar y Ordenar',
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
            if (isAdmin)
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
            // ─── Lista de productos (lazy-loaded) ────────────────────
            if (productos.isEmpty)
              SliverToBoxAdapter(child: _EmptyInventory())
            else
              SliverList.builder(
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        _ProductTile(
                          key: ValueKey(producto.id),
                          producto: producto,
                          isAdmin: isAdmin,
                        ),
                        const _ListSeparator(),
                      ],
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
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
    // RepaintBoundary aísla la rasterización de cada tile (foto + contador
    // de ventas en vivo) del resto de la lista, evitando repintar toda la
    // pantalla cuando cambia el "vendidos hoy" de un solo producto.
    return RepaintBoundary(
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
              ProductPhoto(url: producto.fotoUrl, size: 56),
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
                    Row(
                      children: [
                        Text(
                          '${producto.stockActual} uds.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Mostrar vendidos hoy si existen
                        Builder(
                          builder: (context) {
                            final sold = ref.watch(
                              currentCuadreSalesProvider.select(
                                (sales) => sales.value?[producto.id] ?? 0,
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
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: context.colors.danger,
                          ),
                          Text(
                            ' Stock bajo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: context.colors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ],
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: context.colors.primary),
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
  const _EmptyInventory();

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
            Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: context.colors.muted,
            ),
            const SizedBox(height: AppSpacing.sm),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/categoria.dart';
import '../../turno/providers/turno_provider.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/stat_card.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () =>
                  context.push('/admin/inventario/productos/nuevo'),
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
                        decoration: const InputDecoration(
                          hintText: 'Buscar producto...',
                          prefixIcon: Icon(Icons.search_rounded),
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
            // ─── Stats ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    StatCard(
                      label: 'Total productos',
                      value: state.totalProductos.toString(),
                      tint: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatCard(
                      label: 'Valor total',
                      value: formatCurrency(state.valorTotal),
                      tint: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            // ─── Lista de productos (lazy-loaded) ────────────────────
            if (productos.isEmpty)
              const SliverToBoxAdapter(child: _EmptyInventory())
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

  // ─── Filter bottom sheet ──────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(inventarioControllerProvider);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordenar y Filtrar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Ordenar por',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<ProductoSortBy>(
                      initialValue: state.sortBy,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: ProductoSortBy.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(inventarioControllerProvider.notifier)
                              .setSortBy(val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solo stock bajo'),
                      subtitle: const Text(
                        'Muestra productos con 3 unidades o menos disponibles',
                      ),
                      value: state.soloStockBajo,
                      onChanged: (val) {
                        ref
                            .read(inventarioControllerProvider.notifier)
                            .setSoloStockBajo(val);
                      },
                    ),
                    const Divider(),
                    Text(
                      'Categoría',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Todas'),
                            leading: Icon(
                              state.categoriaId == null
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                            ),
                            onTap: () {
                              ref
                                  .read(inventarioControllerProvider.notifier)
                                  .setCategoria(null);
                            },
                          ),
                          for (final categoria in state.categorias)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(categoria.nombre),
                              leading: Icon(
                                state.categoriaId == categoria.id
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                              ),
                              onTap: () {
                                ref
                                    .read(inventarioControllerProvider.notifier)
                                    .setCategoria(categoria.id);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        onTap: isAdmin
            ? () => context.push('/admin/inventario/productos/${producto.id}')
            : () => _handleDependienteTap(context, ref, producto),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(
                                  left: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  soldLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.warning),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        if (producto.tieneStockBajo) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          Text(
                            ' Stock bajo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(producto.precio),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    isAdmin
                        ? Icons.chevron_right_rounded
                        : Icons.add_circle_outline_rounded,
                    color: AppColors.muted,
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

  void _handleDependienteTap(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
  ) {
    final turno = ref.read(turnoControllerProvider);
    if (!turno.estaActivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia tu turno para registrar ventas')),
      );
      return;
    }
    _showAgregarCuadreSheet(context, ref, producto);
  }

  void _showAgregarCuadreSheet(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
  ) async {
    final cantidad = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _AgregarCuadreSheet(producto: producto),
    );

    // The bottom sheet is fully dismissed and removed from the tree.
    // Now it is safe to mutate providers.
    if (cantidad != null && cantidad > 0) {
      ref
          .read(turnoControllerProvider.notifier)
          .agregarItem(producto, cantidad);
    }
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

// ─── Bottom sheet: agregar al cuadre ───────────────────────────────────────

class _AgregarCuadreSheet extends StatefulWidget {
  const _AgregarCuadreSheet({required this.producto});

  final Producto producto;

  @override
  State<_AgregarCuadreSheet> createState() => _AgregarCuadreSheetState();
}

class _AgregarCuadreSheetState extends State<_AgregarCuadreSheet> {
  final _cantidadController = TextEditingController(text: '1');

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar al cuadre',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(producto.nombre, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 2),
            Text(
              'Stock disponible: ${producto.stockActual} unidades',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _cantidadController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad vendida',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                final cantidad =
                    int.tryParse(_cantidadController.text.trim()) ?? 0;
                if (cantidad <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa una cantidad mayor a 0'),
                    ),
                  );
                  return;
                }
                if (cantidad > producto.stockActual) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La cantidad supera el stock disponible'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(cantidad);
              },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Agregar al cuadre'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
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
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
        shadows: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: AppColors.muted,
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

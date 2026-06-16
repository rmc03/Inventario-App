import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/categoria.dart';
import '../../turno/providers/turno_provider.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/stat_card.dart';
import '../providers/inventario_provider.dart';

class InventarioScreen extends ConsumerWidget {
  const InventarioScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventarioControllerProvider);
    final productos = state.productosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notificaciones',
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/admin/inventario/productos/nuevo'),
              tooltip: 'Crear producto',
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: ref
                        .read(inventarioControllerProvider.notifier)
                        .setSearch,
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: () => _showFilterSheet(context, ref),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filtrar y Ordenar',
                ),
              ],
            ),
            if (state.categoriaId != null ||
                state.soloStockBajo ||
                state.sortBy != ProductoSortBy.nombreAsc) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (state.categoriaId != null) ...[
                      InputChip(
                        label: Text(
                          state.categorias
                              .firstWhere((c) => c.id == state.categoriaId,
                                  orElse: () => Categoria(
                                        id: '',
                                        nombre: '',
                                        createdAt: DateTime.now(),
                                      ))
                              .nombre,
                        ),
                        onDeleted: () => ref
                            .read(inventarioControllerProvider.notifier)
                            .setCategoria(null),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (state.soloStockBajo) ...[
                      InputChip(
                        label: const Text('Solo stock bajo'),
                        onDeleted: () => ref
                            .read(inventarioControllerProvider.notifier)
                            .setSoloStockBajo(false),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (state.sortBy != ProductoSortBy.nombreAsc) ...[
                      InputChip(
                        label: Text('Orden: ${state.sortBy.label}'),
                        onDeleted: () => ref
                            .read(inventarioControllerProvider.notifier)
                            .setSortBy(ProductoSortBy.nombreAsc),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final total = ref.watch(
                      inventarioControllerProvider.select(
                        (s) => s.totalProductos,
                      ),
                    );
                    return StatCard(
                      label: 'Total productos',
                      value: total.toString(),
                      tint: AppColors.primary,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Consumer(
                  builder: (context, ref, _) {
                    final valor = ref.watch(
                      inventarioControllerProvider.select(
                        (s) => s.valorTotal,
                      ),
                    );
                    return StatCard(
                      label: 'Valor total',
                      value: formatCurrency(valor),
                      tint: AppColors.success,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (productos.isEmpty)
              const _EmptyInventory()
            else
              for (final producto in productos) ...[
                _ProductTile(key: ValueKey(producto.id), producto: producto, isAdmin: isAdmin),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordenar y Filtrar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ordenar por',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ProductoSortBy>(
                      value: state.sortBy,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: ProductoSortBy.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(inventarioControllerProvider.notifier)
                              .setSortBy(val);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solo stock bajo'),
                      subtitle: const Text(
                        'Muestra productos que están por debajo del mínimo',
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
                    const SizedBox(height: 8),
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

class _ProductTile extends ConsumerWidget {
  const _ProductTile({super.key, required this.producto, required this.isAdmin});

  final Producto producto;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isAdmin
            ? () => context.push('/admin/inventario/productos/${producto.id}')
            : () => _handleDependienteTap(context, ref, producto),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RepaintBoundary(
                child: ProductPhoto(url: producto.fotoUrl, size: 56),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Stock: ${producto.stockActual}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (producto.tieneStockBajo) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.danger,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(producto.precio),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    isAdmin
                        ? Icons.chevron_right_rounded
                        : Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
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
        const SnackBar(
          content: Text('Inicia tu turno para registrar ventas'),
        ),
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
      builder: (sheetCtx) => _AgregarCuadreSheet(
        producto: producto,
      ),
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
          20,
          0,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar al cuadre',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Stock disponible: ${producto.stockActual} unidades',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad vendida',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 18),
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
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Sin productos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
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

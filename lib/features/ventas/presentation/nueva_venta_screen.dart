import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre_item.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/qty_controls.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../../turno/providers/turno_provider.dart';
import '../providers/venta_provider.dart';

class NuevaVentaScreen extends ConsumerStatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  ConsumerState<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends ConsumerState<NuevaVentaScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Iniciar venta si no existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(ventaEnCursoProvider) == null) {
        ref.read(ventaEnCursoProvider.notifier).iniciarVenta();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ventaEnCurso = ref.watch(ventaEnCursoProvider);
    final allProducts = ref.watch(inventarioControllerProvider).productos;

    final productos = _searchQuery.trim().isEmpty
        ? allProducts.where((p) => p.activo && p.stockActual > 0).toList()
        : allProducts.where((p) {
            final normalizedQuery = _searchQuery.trim().toLowerCase();
            return p.activo &&
                p.stockActual > 0 &&
                p.nombre.toLowerCase().contains(normalizedQuery);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva venta'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(ventaEnCursoProvider.notifier).cancelarVenta();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.pillBorder,
                    borderSide: BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.pillBorder,
                    borderSide: BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.pillBorder,
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // Lista de productos
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: productos.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Divider(height: 1, indent: 72),
                ),
                itemBuilder: (context, index) {
                  final p = productos[index];
                  final qtyInCart = ventaEnCurso?.items
                          .where((i) => i.productoId == p.id)
                          .fold(0, (sum, i) => sum + i.cantidad) ?? 0;

                  return _ProductoVentaTile(
                    producto: p,
                    qtyInCart: qtyInCart,
                    onAdd: () {
                      final turnoState = ref.read(turnoControllerProvider);
                      if (!turnoState.permitirVentas) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pueden registrar ventas: turno cerrado')),
                        );
                        return;
                      }
                      final ventaCtrl = ref.read(ventaEnCursoProvider.notifier);
                      if (qtyInCart == 0) {
                        if (p.stockActual <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sin stock')),
                          );
                          return;
                        }
                        ventaCtrl.agregarProducto(CuadreItem(
                          productoId: p.id,
                          productoNombre: p.nombre,
                          cantidad: 1,
                          precioUnitario: p.precio,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Agregado al carrito')),
                        );
                        return;
                      }
                      // si ya tiene qty mostrar el sheet para edición avanzada
                      _showQtySheet(context, p);
                    },
                    onIncrement: () {
                      final turnoState = ref.read(turnoControllerProvider);
                      if (!turnoState.permitirVentas) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pueden registrar ventas: turno cerrado')),
                        );
                        return;
                      }
                      final ventaCtrl = ref.read(ventaEnCursoProvider.notifier);
                      final pFound = ref.read(inventarioControllerProvider.notifier).findProducto(p.id);
                      if (pFound != null && qtyInCart + 1 > pFound.stockActual) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sin stock')),
                        );
                        return;
                      }
                      ventaCtrl.actualizarCantidadItem(p.id, qtyInCart + 1);
                    },
                    onDecrement: () {
                      final turnoState = ref.read(turnoControllerProvider);
                      if (!turnoState.permitirVentas) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pueden registrar ventas: turno cerrado')),
                        );
                        return;
                      }
                      final ventaCtrl = ref.read(ventaEnCursoProvider.notifier);
                      if (qtyInCart - 1 <= 0) {
                        ventaCtrl.eliminarItem(p.id);
                      } else {
                        ventaCtrl.actualizarCantidadItem(p.id, qtyInCart - 1);
                      }
                    },
                    onLongPress: () => _showQtySheet(context, p),
                  );
                },
              ),
            ),

            // Carrito bottom bar
            if (ventaEnCurso != null && ventaEnCurso.items.isNotEmpty)
              _CartBottomBar(
                onShowCart: () => _showCartSheet(context),
                onComplete: () async {
                  // Navegar a pantalla de confirmar pago
                  final res = await context.push<bool>('/dependiente/turno/confirmar-pago');
                  // Si se confirmó y regresó true, cerrar la pantalla de nueva venta
                  if (res == true) {
                    if (context.mounted) context.pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showQtySheet(BuildContext context, Producto p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AddQtySheet(producto: p),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => const _CartSheet(),
    );
  }
}

// ─── Componentes ─────────────────────────────────────────────────────────────

class _ProductoVentaTile extends StatelessWidget {
  const _ProductoVentaTile({
    required this.producto,
    required this.qtyInCart,
    required this.onAdd,
    this.onIncrement,
    this.onDecrement,
    this.onLongPress,
  });

  final Producto producto;
  final int qtyInCart;
  final VoidCallback onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      onLongPress: onLongPress,
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
                        '${producto.stockActual} disp.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (qtyInCart > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$qtyInCart en carrito',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                qtyInCart > 0
                    ? QtyControls(
                        cantidad: qtyInCart,
                        onDecrement: onDecrement,
                        onIncrement: onIncrement ?? () {},
                      )
                    : const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.muted,
                        size: 24,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddQtySheet extends ConsumerStatefulWidget {
  const _AddQtySheet({required this.producto});
  final Producto producto;

  @override
  ConsumerState<_AddQtySheet> createState() => _AddQtySheetState();
}

class _AddQtySheetState extends ConsumerState<_AddQtySheet> {
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
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
            Text('Añadir a venta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(p.nombre, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 2),
            Text(
              'Stock disponible: ${p.stockActual}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) return;
                
                // Fetch the current qty in cart for this product
                final ventaEnCurso = ref.read(ventaEnCursoProvider);
                final qtyInCart = ventaEnCurso?.items
                        .where((i) => i.productoId == p.id)
                        .fold(0, (sum, i) => sum + i.cantidad) ?? 0;

                if (qtyInCart + qty > p.stockActual) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cantidad supera el stock')),
                  );
                  return;
                }
                
                ref.read(ventaEnCursoProvider.notifier).agregarProducto(
                      CuadreItem(
                        productoId: p.id,
                        productoNombre: p.nombre,
                        cantidad: qty,
                        precioUnitario: p.precio,
                      ),
                    );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Agregar'),
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

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({
    required this.onShowCart,
    required this.onComplete,
  });

  final VoidCallback onShowCart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final venta = ref.watch(ventaEnCursoProvider);
        if (venta == null) return const SizedBox.shrink();

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.line)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onShowCart,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_cart_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${venta.totalUnidades} items',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatCurrency(venta.total),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Completar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartSheet extends ConsumerWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venta = ref.watch(ventaEnCursoProvider);
    if (venta == null || venta.items.isEmpty) {
      return const SafeArea(child: SizedBox(height: 100));
    }

    final ctrl = ref.read(ventaEnCursoProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Carrito', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    formatCurrency(venta.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: venta.items.length,
                itemBuilder: (ctx, i) {
                  final item = venta.items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productoNombre,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatCurrency(item.precioUnitario)} c/u',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          QtyControls(
                            cantidad: item.cantidad,
                            onDecrement: item.cantidad > 1
                                ? () => ctrl.actualizarCantidadItem(
                                      item.productoId,
                                      item.cantidad - 1,
                                    )
                                : null,
                            onIncrement: () {
                              final p = ref
                                  .read(inventarioControllerProvider.notifier)
                                  .findProducto(item.productoId);
                              if (p != null && item.cantidad + 1 > p.stockActual) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sin stock')),
                                );
                                return;
                              }
                              ctrl.actualizarCantidadItem(
                                item.productoId,
                                item.cantidad + 1,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                            onPressed: () => ctrl.eliminarItem(item.productoId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

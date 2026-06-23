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
import '../../inventario/data/producto_repository.dart';
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
  String? _selectedCategoriaId;

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
    final inventarioState = ref.watch(inventarioControllerProvider);
    final allProducts = inventarioState.productos.isEmpty
        ? demoProductos()
        : inventarioState.productos;
    final categorias = inventarioState.categorias.isEmpty
        ? demoCategorias()
        : inventarioState.categorias;

    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final productos = allProducts.where((p) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          p.nombre.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          _selectedCategoriaId == null || p.categoriaId == _selectedCategoriaId;
      return p.activo && p.stockActual > 0 && matchesSearch && matchesCategory;
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
      bottomNavigationBar: _CartBottomBar(
        onShowCart: () => _showCartSheet(context),
        onComplete: () async {
          final res = await context.push<bool>(
            '/dependiente/turno/confirmar-pago',
          );
          if (res == true) {
            if (context.mounted) context.pop();
          }
        },
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  TextField(
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
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _CategoryChip(
                                label: 'Todos',
                                selected: _selectedCategoriaId == null,
                                onTap: () =>
                                    setState(() => _selectedCategoriaId = null),
                              ),
                              for (final categoria in categorias) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _CategoryChip(
                                  label: categoria.nombre,
                                  selected:
                                      _selectedCategoriaId == categoria.id,
                                  onTap: () => setState(
                                    () => _selectedCategoriaId = categoria.id,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed: () => _showCategoryFilterSheet(context),
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: 'Filtrar productos',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: productos.isEmpty
                  ? const _EmptyProductList()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                      ),
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        final p = productos[index];
                        final qtyInCart =
                            ventaEnCurso?.items
                                .where((i) => i.productoId == p.id)
                                .fold(0, (sum, i) => sum + i.cantidad) ??
                            0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _ProductoVentaTile(
                            key: ValueKey(p.id),
                            producto: p,
                            qtyInCart: qtyInCart,
                            onAdd: () {
                              final turnoState = ref.read(
                                turnoControllerProvider,
                              );
                              if (!turnoState.permitirVentas) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pueden registrar ventas: turno cerrado',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final ventaCtrl = ref.read(
                                ventaEnCursoProvider.notifier,
                              );
                              if (qtyInCart == 0) {
                                if (p.stockActual <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sin stock')),
                                  );
                                  return;
                                }
                                ventaCtrl.agregarProducto(
                                  CuadreItem(
                                    productoId: p.id,
                                    productoNombre: p.nombre,
                                    cantidad: 1,
                                    precioUnitario: p.precio,
                                  ),
                                );
                                return;
                              }
                              _showQtySheet(context, p);
                            },
                            onIncrement: () {
                              final turnoState = ref.read(
                                turnoControllerProvider,
                              );
                              if (!turnoState.permitirVentas) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pueden registrar ventas: turno cerrado',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final ventaCtrl = ref.read(
                                ventaEnCursoProvider.notifier,
                              );
                              final pFound = ref
                                  .read(inventarioControllerProvider.notifier)
                                  .findProducto(p.id);
                              final currentProduct = pFound ?? p;
                              if (qtyInCart + 1 > currentProduct.stockActual) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sin stock')),
                                );
                                return;
                              }
                              ventaCtrl.actualizarCantidadItem(
                                p.id,
                                qtyInCart + 1,
                              );
                            },
                            onDecrement: () {
                              final turnoState = ref.read(
                                turnoControllerProvider,
                              );
                              if (!turnoState.permitirVentas) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pueden registrar ventas: turno cerrado',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final ventaCtrl = ref.read(
                                ventaEnCursoProvider.notifier,
                              );
                              if (qtyInCart - 1 <= 0) {
                                ventaCtrl.eliminarItem(p.id);
                              } else {
                                ventaCtrl.actualizarCantidadItem(
                                  p.id,
                                  qtyInCart - 1,
                                );
                              }
                            },
                            onLongPress: () => _showQtySheet(context, p),
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

  void _showCategoryFilterSheet(BuildContext context) {
    final inventarioCategorias = ref
        .read(inventarioControllerProvider)
        .categorias;
    final categorias = inventarioCategorias.isEmpty
        ? demoCategorias()
        : inventarioCategorias;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por categoría',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apps_rounded),
                title: const Text('Todos'),
                trailing: _selectedCategoriaId == null
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedCategoriaId = null);
                  Navigator.of(ctx).pop();
                },
              ),
              for (final categoria in categorias)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category_outlined),
                  title: Text(categoria.nombre),
                  trailing: _selectedCategoriaId == categoria.id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedCategoriaId = categoria.id);
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Componentes ─────────────────────────────────────────────────────────────

String _articulosLabel(int total) {
  return total == 1 ? '1 artículo' : '$total artículos';
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pillBorder,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceSecondary,
          borderRadius: AppRadii.pillBorder,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProductoVentaTile extends StatelessWidget {
  const _ProductoVentaTile({
    super.key,
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
    final isSelected = qtyInCart > 0;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgBorder),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        onLongPress: onLongPress,
        borderRadius: AppRadii.lgBorder,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 5,
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    ProductPhoto(url: producto.fotoUrl, size: 66),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text.rich(
                            TextSpan(
                              text: 'Stock: ${producto.stockActual} ',
                              children: const [
                                TextSpan(
                                  text: 'disponibles',
                                  style: TextStyle(color: AppColors.success),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 102),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(producto.precio),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          isSelected
                              ? _InlineQtySelector(
                                  cantidad: qtyInCart,
                                  onDecrement: onDecrement,
                                  onIncrement: onIncrement,
                                )
                              : _AddProductButton(onPressed: onAdd),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        side: const BorderSide(color: AppColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillBorder),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
      child: const Text('+ Agregar'),
    );
  }
}

class _InlineQtySelector extends StatelessWidget {
  const _InlineQtySelector({
    required this.cantidad,
    this.onDecrement,
    this.onIncrement,
  });

  final int cantidad;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyRoundButton(
          icon: Icons.remove_rounded,
          onPressed: onDecrement,
          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
          foregroundColor: AppColors.primary,
        ),
        Container(
          height: 34,
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: AppRadii.smBorder,
          ),
          child: Text(
            cantidad.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        _QtyRoundButton(
          icon: Icons.add_rounded,
          onPressed: onIncrement,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }
}

class _QtyRoundButton extends StatelessWidget {
  const _QtyRoundButton({
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: foregroundColor,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: AppColors.surfaceSecondary,
          disabledForegroundColor: AppColors.muted,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.smBorder),
        ),
      ),
    );
  }
}

class _EmptyProductList extends StatelessWidget {
  const _EmptyProductList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: AppRadii.xlBorder,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.muted,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay productos disponibles',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Prueba con otra búsqueda o categoría.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
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
            Text(
              'Añadir a venta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                final qtyInCart =
                    ventaEnCurso?.items
                        .where((i) => i.productoId == p.id)
                        .fold(0, (sum, i) => sum + i.cantidad) ??
                    0;

                if (qtyInCart + qty > p.stockActual) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cantidad supera el stock')),
                  );
                  return;
                }

                ref
                    .read(ventaEnCursoProvider.notifier)
                    .agregarProducto(
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
  const _CartBottomBar({required this.onShowCart, required this.onComplete});

  final VoidCallback onShowCart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final venta = ref.watch(ventaEnCursoProvider);
        final totalArticulos = venta?.totalUnidades ?? 0;
        final total = venta?.total ?? 0;
        final hasItems = totalArticulos > 0;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: hasItems ? onShowCart : null,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: AppRadii.lgBorder,
                              ),
                              child: const Icon(
                                Icons.shopping_cart_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              right: -3,
                              top: -5,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  totalArticulos.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _articulosLabel(totalArticulos),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ver carrito',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.primary),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasItems ? onComplete : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.lgBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Cobrar ${formatCurrency(total)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
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
                  Text(
                    'Carrito',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    formatCurrency(venta.total),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
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
                              if (p != null &&
                                  item.cantidad + 1 > p.stockActual) {
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
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
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

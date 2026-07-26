import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/cuadre_item.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/qty_controls.dart';
import '../../../shared/widgets/filter_sort_sheet.dart';
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
  ProductoSortBy _selectedSortBy = ProductoSortBy.nombreAsc;
  bool _soloStockBajo = false;

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
    var productos = allProducts.where((p) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          p.nombre.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          _selectedCategoriaId == null || p.categoriaId == _selectedCategoriaId;
      final matchesStockBajo = !_soloStockBajo || p.tieneStockBajo;
      return p.activo && p.stockActual > 0 && matchesSearch && matchesCategory && matchesStockBajo;
    }).toList();

    switch (_selectedSortBy) {
      case ProductoSortBy.nombreAsc:
        productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      case ProductoSortBy.precioAsc:
        productos.sort((a, b) => a.precio.compareTo(b.precio));
      case ProductoSortBy.precioDesc:
        productos.sort((a, b) => b.precio.compareTo(a.precio));
      case ProductoSortBy.stockAsc:
        productos.sort((a, b) => a.stockActual.compareTo(b.stockActual));
      case ProductoSortBy.stockDesc:
        productos.sort((a, b) => b.stockActual.compareTo(a.stockActual));
    }

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
          await context.push<bool>(
            '/dependiente/turno/confirmar-pago',
          );
          // No hacer nada aquí - ConfirmarPago hace ambos pops
        },
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
          children: [
            // ── Barra de búsqueda + botón filtrar (sticky) ──
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.pillBorder,
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.primary.withValues(
                                  alpha: _searchQuery.isNotEmpty ? 0.08 : 0.03,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: false,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar producto...',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: context.colors.muted,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 24,
                                color: _searchQuery.isNotEmpty
                                    ? context.colors.primary
                                    : context.colors.muted,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? _AnimatedClearButton(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
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
                        isActive: _selectedSortBy != ProductoSortBy.nombreAsc || _soloStockBajo,
                        onPressed: () => _showFilterSheet(context),
                      ),
                    ],
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
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
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

                        return _StaggeredFadeSlide(
                          index: index,
                          child: Padding(
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
                            onQtyTap: () => _showQtySheet(context, p),
                          ),
                        ),
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

  void _showFilterSheet(BuildContext context) {
    final categorias = ref.read(inventarioControllerProvider).categorias.isEmpty
        ? demoCategorias()
        : ref.read(inventarioControllerProvider).categorias;
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => FilterSortSheet(
        initialSortBy: _selectedSortBy,
        initialCategoriaId: _selectedCategoriaId,
        initialSoloStockBajo: _soloStockBajo,
        categorias: categorias,
        title: 'Ordenar y Filtrar',
        onApply: ({
          required sortBy,
          required categoriaId,
          required soloStockBajo,
        }) {
          setState(() {
            _selectedSortBy = sortBy;
            _selectedCategoriaId = categoriaId;
            _soloStockBajo = soloStockBajo;
          });
        },
      ),
    );
  }
}

class _StaggeredFadeSlide extends StatefulWidget {
  const _StaggeredFadeSlide({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 30).clamp(0, 300));
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
          color: selected ? context.colors.primary : context.colors.surfaceSecondary,
          borderRadius: AppRadii.pillBorder,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? Colors.white : context.colors.ink,
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
    this.onQtyTap,
  });

  final Producto producto;
  final int qtyInCart;
  final VoidCallback onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onLongPress;
  final VoidCallback? onQtyTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = qtyInCart > 0;

    return Card(
      color: context.colors.surface,
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
              color: isSelected ? context.colors.primary : Colors.transparent,
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
                              children: [
                                TextSpan(
                                  text: 'disponibles',
                                  style: TextStyle(color: context.colors.success),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(producto.precio),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 34,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: isSelected
                                ? _InlineQtySelector(
                                    key: const ValueKey('qty'),
                                    cantidad: qtyInCart,
                                    onDecrement: onDecrement,
                                    onIncrement: onIncrement,
                                    onTap: onQtyTap,
                                  )
                                : _AddProductButton(
                                    key: const ValueKey('add'),
                                    onPressed: onAdd,
                                  ),
                          ),
                        ),
                      ],
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
  const _AddProductButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.primary,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        side: BorderSide(color: context.colors.primary),
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
    super.key,
    required this.cantidad,
    this.onDecrement,
    this.onIncrement,
    this.onTap,
  });

  final int cantidad;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyRoundButton(
          icon: Icons.remove_rounded,
          onPressed: onDecrement,
          backgroundColor: context.colors.surfaceSecondary,
          foregroundColor: context.colors.ink,
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 34,
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.line),
              borderRadius: AppRadii.smBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cantidad.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        _QtyRoundButton(
          icon: Icons.add_rounded,
          onPressed: onIncrement,
          backgroundColor: context.colors.surfaceSecondary,
          foregroundColor: context.colors.ink,
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
          disabledBackgroundColor: context.colors.surfaceSecondary,
          disabledForegroundColor: context.colors.muted,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.smBorder),
        ),
      ),
    );
  }
}

class _EmptyProductList extends StatefulWidget {
  const _EmptyProductList();

  @override
  State<_EmptyProductList> createState() => _EmptyProductListState();
}

class _EmptyProductListState extends State<_EmptyProductList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceSecondary,
                    borderRadius: AppRadii.xlBorder,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    color: context.colors.muted,
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

class _CartBottomBar extends ConsumerStatefulWidget {
  const _CartBottomBar({required this.onShowCart, required this.onComplete});

  final VoidCallback onShowCart;
  final VoidCallback onComplete;

  @override
  ConsumerState<_CartBottomBar> createState() => _CartBottomBarState();
}

class _CartBottomBarState extends ConsumerState<_CartBottomBar>
    with TickerProviderStateMixin {
  late final AnimationController _totalCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  double _prevTotal = 0;
  double _animFrom = 0;
  double _animTo = 0;

  @override
  void initState() {
    super.initState();
    _totalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutBack),
    );
    _pulseCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaEnCursoProvider);
    final totalArticulos = venta?.totalUnidades ?? 0;
    final total = venta?.total ?? 0;
    final hasItems = totalArticulos > 0;

    if (total != _prevTotal) {
      _animFrom = _prevTotal;
      _animTo = total;
      _prevTotal = total;
      _totalCtrl.forward(from: 0);
      if (total > _animFrom && hasItems) {
        _pulseCtrl.forward(from: 0);
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.10),
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
                onTap: hasItems ? widget.onShowCart : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulse.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: AppRadii.lgBorder,
                        ),
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          color: context.colors.primary,
                        ),
                      ),
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
                                  ?.copyWith(color: context.colors.primary),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: context.colors.primary,
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
                  onPressed: hasItems
                      ? () {
                          Haptics.confirm(context);
                          widget.onComplete();
                        }
                      : null,
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
                        child: AnimatedBuilder(
                          animation: _totalCtrl,
                          builder: (context, child) {
                            final displayTotal = _animFrom +
                                (_totalCtrl.value * (_animTo - _animFrom));
                            return Text(
                              'Cobrar ${formatCurrency(displayTotal)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
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
                    ).textTheme.titleMedium?.copyWith(color: context.colors.primary),
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
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: context.colors.danger,
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

// ═══════════════════════════════════════════════════════════════════════════
// Widgets auxiliares para la barra de búsqueda mejorada
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedClearButton extends StatefulWidget {
  const _AnimatedClearButton({required this.onPressed});
  
  final VoidCallback onPressed;

  @override
  State<_AnimatedClearButton> createState() => _AnimatedClearButtonState();
}

class _AnimatedClearButtonState extends State<_AnimatedClearButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: const Icon(Icons.close_rounded, size: 20),
        onPressed: widget.onPressed,
        color: Theme.of(context).extension<AppColorsExtension>()?.muted,
      ),
    );
  }
}

class _AnimatedFilterButton extends StatelessWidget {
  const _AnimatedFilterButton({
    required this.isActive,
    required this.onPressed,
  });

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(
          Icons.tune_rounded,
          color: isActive ? context.colors.primary : null,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isActive
              ? context.colors.primary.withValues(alpha: 0.15)
              : null,
        ),
      ),
    );
  }
}

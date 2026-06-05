import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/stock_badge.dart';
import '../providers/inventario_provider.dart';

class ProductoDetalleScreen extends ConsumerWidget {
  const ProductoDetalleScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final producto = ref
        .watch(inventarioControllerProvider.notifier)
        .findProducto(productId);

    if (producto == null || !producto.activo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        leading: IconButton(
          onPressed: () => context.go('/admin/inventario'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            onPressed: () =>
                context.go('/admin/inventario/productos/${producto.id}/editar'),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ProductPhoto(
                  url: producto.fotoUrl,
                  size: 188,
                  iconSize: 72,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  'SKU: ${producto.codigoRef ?? producto.id}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Categoría',
              value: producto.categoriaNombre ?? 'Sin categoría',
            ),
            _DetailRow(
              icon: Icons.inventory_outlined,
              label: 'Stock disponible',
              customValue: StockBadge(
                stock: producto.stockActual,
                isLow: producto.tieneStockBajo,
              ),
            ),
            _DetailRow(
              icon: Icons.paid_outlined,
              label: 'Precio unitario',
              value: formatCurrency(producto.precio),
            ),
            _DetailRow(
              icon: Icons.assessment_outlined,
              label: 'Valor total',
              value: formatCurrency(producto.valorTotal),
            ),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref, producto),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar producto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 42,
          ),
          title: const Text('¿Eliminar producto?'),
          content: Text(
            'Esta acción no se puede deshacer. ¿Deseas eliminar ${producto.nombre}?',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      ref
          .read(inventarioControllerProvider.notifier)
          .deleteProducto(producto.id);
      if (context.mounted) {
        context.go('/admin/inventario');
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.customValue,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? customValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              customValue ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/stock_badge.dart';
import '../providers/inventario_provider.dart';

class ProductoDetalleScreen extends ConsumerWidget {
  const ProductoDetalleScreen({
    super.key,
    required this.productId,
    this.isAdmin = true,
  });

  final String productId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selecciona solo el producto por id: evita rebuilds cuando cambia
    // búsqueda, filtros, orden u otros productos del inventario.
    final producto = ref.watch(
      inventarioControllerProvider.select(
        (s) => s.productos.where((p) => p.id == productId).firstOrNull,
      ),
    );

    if (producto == null || !producto.activo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    final descripcion = producto.descripcion?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () =>
                  context.push('/admin/inventario/productos/${producto.id}/editar'),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Editar',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl,
          ),
          children: [
            // ─── Foto ────────────────────────────────────────────────────
            DecoratedBox(
              decoration: ShapeDecoration(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                shadows: AppShadows.subtle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ProductPhoto(
                  url: producto.fotoUrl,
                  size: 188,
                  iconSize: 72,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ─── Nombre ──────────────────────────────────────────────────
            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (descripcion != null && descripcion.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            // ─── Sección: Producto ────────────────────────────────────────
            _SectionHeader(title: 'PRODUCTO'),
            _GroupedCard(
              children: [
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: producto.categoriaNombre ?? 'Sin categoría',
                ),
                const _CardSeparator(),
                _DetailRow(
                  icon: Icons.paid_outlined,
                  label: 'Precio por Unidad',
                  value: formatCurrency(producto.precio),
                ),
              ],
            ),
            // ─── Sección: Inventario ──────────────────────────────────────
            _SectionHeader(title: 'INVENTARIO'),
            _GroupedCard(
              children: [
                _DetailRow(
                  icon: Icons.inventory_outlined,
                  label: 'Stock disponible',
                  customValue: StockBadge(
                    stock: producto.stockActual,
                    isLow: producto.tieneStockBajo,
                  ),
                ),
                const _CardSeparator(),
                if (isAdmin)
                  _DetailRow(
                    icon: Icons.assessment_outlined,
                    label: 'Valor total',
                    value: formatCurrency(producto.valorTotal),
                  ),
              ],
            ),
            // ─── Eliminar ────────────────────────────────────────────────
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.xl),
              _GroupedCard(
                children: [
                  _DeleteButton(producto: producto),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helpers de sección agrupada estilo iOS ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
        shadows: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdBorder,
        child: Column(children: children),
      ),
    );
  }
}

class _CardSeparator extends StatelessWidget {
  const _CardSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: AppSpacing.xxl),
      child: Divider(height: 1, indent: 0),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          customValue ??
              Text(
                value ?? '',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
        ],
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _confirmDelete(context, ref, producto),
      borderRadius: AppRadii.mdBorder,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Text(
            'Eliminar producto',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
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

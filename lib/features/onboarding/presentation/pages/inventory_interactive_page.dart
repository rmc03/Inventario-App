import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../widgets/interactive_product_card.dart';

/// Página 2: Inventario interactivo con Hero transition
class InventoryInteractivePage extends StatefulWidget {
  const InventoryInteractivePage({super.key});

  @override
  State<InventoryInteractivePage> createState() =>
      _InventoryInteractivePageState();
}

class _InventoryInteractivePageState extends State<InventoryInteractivePage>
    with TickerProviderStateMixin {
  DemoProduct? _selectedProduct;
  late AnimationController _detailController;
  late Animation<double> _detailFadeAnim;
  late Animation<Offset> _detailSlideAnim;
  bool _showConfirmation = false;

  @override
  void initState() {
    super.initState();
    _detailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _detailFadeAnim = CurvedAnimation(
      parent: _detailController,
      curve: Curves.easeOut,
    );
    _detailSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_detailFadeAnim);
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _openProductDetail(DemoProduct product) {
    Haptics.confirm(context);
    setState(() {
      _selectedProduct = product;
      _showConfirmation = false;
    });
    _detailController.forward();

    // Auto-cerrar después de 2.5 seg
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _selectedProduct != null) {
        _closeProductDetail();
      }
    });
  }

  void _closeProductDetail() {
    setState(() => _showConfirmation = true);
    _detailController.reverse().then((_) {
      if (mounted) {
        setState(() => _selectedProduct = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        // Contenido principal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Título
              Text(
                'Tu inventario, siempre al día',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.ink,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Descripción
              Text(
                'Agrega productos, controla stock, recibe alertas.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Instrucción (solo si no hay producto seleccionado)
              if (_selectedProduct == null && !_showConfirmation)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(25), // 0.1
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👆', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Toca un producto para ver detalles',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

              // Mensaje de confirmación
              if (_showConfirmation)
                FadeTransition(
                  opacity: _detailFadeAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success.withAlpha(25), // 0.1
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: colors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Así de fácil es gestionar productos',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Grid de productos
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: DemoProducts.products.length,
                  itemBuilder: (context, index) {
                    final product = DemoProducts.products[index];
                    return InteractiveProductCard(
                      product: product,
                      heroTag: 'product_$index',
                      onTap: () => _openProductDetail(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Detalle del producto (overlay)
        if (_selectedProduct != null)
          _ProductDetailOverlay(
            product: _selectedProduct!,
            fadeAnim: _detailFadeAnim,
            slideAnim: _detailSlideAnim,
            onClose: _closeProductDetail,
          ),
      ],
    );
  }
}

class _ProductDetailOverlay extends StatelessWidget {
  const _ProductDetailOverlay({
    required this.product,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onClose,
  });

  final DemoProduct product;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      opacity: fadeAnim,
      child: Container(
        color: colors.background.withAlpha(230), // 0.9
        child: SafeArea(
          child: Column(
            children: [
              // Header con botón cerrar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: onClose,
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Contenido del detalle
              Expanded(
                child: SlideTransition(
                  position: slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ícono grande
                        Hero(
                          tag: 'product_${DemoProducts.products.indexOf(product)}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    colors.primary.withAlpha(51), // 0.2
                                    colors.primary.withAlpha(25), // 0.1
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                product.icon,
                                color: colors.primary,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Nombre
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Detalles
                        _DetailRow(
                          label: 'Precio',
                          value: '\$${product.price.toInt()}',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DetailRow(
                          label: 'Stock',
                          value: '${product.stock} unidades',
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Botones (deshabilitados, solo visual)
                        _DisabledButton(
                          label: 'Agregar stock',
                          icon: LucideIcons.plus,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _DisabledButton(
                          label: 'Editar producto',
                          icon: LucideIcons.edit,
                        ),
                      ],
                    ),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.muted,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _DisabledButton extends StatelessWidget {
  const _DisabledButton({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.line,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colors.muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

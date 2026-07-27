import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../widgets/interactive_product_card.dart';

/// Página 3: Simulador de POS interactivo
class SalesInteractivePage extends StatefulWidget {
  const SalesInteractivePage({super.key});

  @override
  State<SalesInteractivePage> createState() => _SalesInteractivePageState();
}

class _SalesInteractivePageState extends State<SalesInteractivePage>
    with TickerProviderStateMixin {
  final List<DemoProduct> _cart = [];
  double _total = 0.0;
  bool _showConfirmButton = false;
  bool _saleCompleted = false;

  late AnimationController _cartItemController;
  late AnimationController _successController;
  DemoProduct? _flyingProduct;
  Offset _flyingStartPosition = Offset.zero;

  final GlobalKey _cartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cartItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _cartItemController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _addToCart(DemoProduct product, Offset startPosition) {
    Haptics.confirm(context);
    
    setState(() {
      _flyingProduct = product;
      _flyingStartPosition = startPosition;
      _cart.add(product);
      _total += product.price;
      _showConfirmButton = _cart.length >= 2;
    });

    _cartItemController.forward(from: 0);
  }

  void _confirmSale() {
    Haptics.confirm(context);
    setState(() => _saleCompleted = true);
    _successController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Título
                Text(
                  'Vende rápido y cobra bien',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.ink,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // Descripción
                Text(
                  'Cobra en efectivo, tarjeta o transferencia.\nEl cuadre se hace solo.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.muted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Instrucción
                if (!_saleCompleted && _cart.isEmpty)
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
                          'Agrega productos al carrito',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Productos disponibles
                if (!_saleCompleted) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Productos disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...DemoProducts.products.take(3).map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ProductRow(
                        product: product,
                        onAdd: (position) => _addToCart(product, position),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Carrito
                _CartSection(
                  key: _cartKey,
                  cart: _cart,
                  total: _total,
                  showConfirmButton: _showConfirmButton,
                  saleCompleted: _saleCompleted,
                  onConfirm: _confirmSale,
                ),

                const SizedBox(height: 120), // Espacio para el botón flotante
              ],
            ),
          ),
        ),

        // Producto volando hacia el carrito
        if (_flyingProduct != null)
          _FlyingProduct(
            product: _flyingProduct!,
            startPosition: _flyingStartPosition,
            endPosition: _getCartPosition(),
            animation: _cartItemController,
          ),

        // Success overlay
        if (_saleCompleted)
          _SuccessOverlay(animation: _successController),
      ],
    );
  }

  Offset _getCartPosition() {
    try {
      final RenderBox? box =
          _cartKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        return Offset(position.dx + box.size.width / 2, position.dy);
      }
    } catch (_) {}
    return const Offset(200, 500);
  }
}

class _ProductRow extends StatefulWidget {
  const _ProductRow({
    required this.product,
    required this.onAdd,
  });

  final DemoProduct product;
  final Function(Offset) onAdd;

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isPressed = false;

  void _handleAdd() {
    try {
      final RenderBox? box =
          _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        widget.onAdd(position);
      }
    } catch (_) {
      widget.onAdd(Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors.primary.withAlpha(51), // 0.2
                  colors.primary.withAlpha(25), // 0.1
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.product.icon,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Nombre y precio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '\$${widget.product.price.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                ),
              ],
            ),
          ),

          // Botón +
          GestureDetector(
            key: _buttonKey,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _handleAdd();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSection extends StatelessWidget {
  const _CartSection({
    super.key,
    required this.cart,
    required this.total,
    required this.showConfirmButton,
    required this.saleCompleted,
    required this.onConfirm,
  });

  final List<DemoProduct> cart;
  final double total;
  final bool showConfirmButton;
  final bool saleCompleted;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: colors.line,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.shoppingCart, size: 20, color: colors.muted),
              const SizedBox(width: 8),
              Text(
                'Carrito',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (cart.isNotEmpty && !saleCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cart.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Items o mensaje vacío
          if (cart.isEmpty && !saleCompleted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Vacío',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                    ),
              ),
            )
          else if (!saleCompleted)
            ...cart.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        p.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        '\$${p.price.toInt()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                )),

          if (cart.isNotEmpty && !saleCompleted) ...[
            const Divider(height: AppSpacing.lg),
            // Total con animación
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Row(
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${value.toInt()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                    ),
                  ],
                );
              },
            ),
          ],

          // Botón confirmar
          if (showConfirmButton && !saleCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            AnimatedSlide(
              offset: showConfirmButton ? Offset.zero : const Offset(0, 0.5),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: showConfirmButton ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: const Text(
                      'Confirmar venta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlyingProduct extends StatelessWidget {
  const _FlyingProduct({
    required this.product,
    required this.startPosition,
    required this.endPosition,
    required this.animation,
  });

  final DemoProduct product;
  final Offset startPosition;
  final Offset endPosition;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        
        // Calcular posición con curva (trayectoria parabólica)
        final dx = startPosition.dx + 
            (endPosition.dx - startPosition.dx) * curvedValue;
        final dy = startPosition.dy + 
            (endPosition.dy - startPosition.dy) * curvedValue -
            math.sin(curvedValue * math.pi) * 50; // Arco

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: 1 - curvedValue,
            child: Transform.scale(
              scale: 1 - curvedValue * 0.5,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withAlpha(76),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  product.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      opacity: animation,
      child: Container(
        color: colors.background.withAlpha(230), // 0.9
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '¡Venta registrada! 🎉',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

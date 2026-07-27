import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';

/// Modelo de producto demo para onboarding
class DemoProduct {
  const DemoProduct({
    required this.name,
    required this.stock,
    required this.price,
    required this.icon,
    this.isLowStock = false,
  });

  final String name;
  final int stock;
  final double price;
  final IconData icon;
  final bool isLowStock;
}

/// Card de producto interactivo para el onboarding
class InteractiveProductCard extends StatefulWidget {
  const InteractiveProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.heroTag,
  });

  final DemoProduct product;
  final VoidCallback onTap;
  final String? heroTag;

  @override
  State<InteractiveProductCard> createState() =>
      _InteractiveProductCardState();
}

class _InteractiveProductCardState extends State<InteractiveProductCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _badgeController;

  @override
  void initState() {
    super.initState();
    if (widget.product.isLowStock) {
      _badgeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);
    } else {
      _badgeController = AnimationController(vsync: this);
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget card = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Haptics.tap(context);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: colors.line,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withAlpha(15), // 0.06 * 255
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono del producto
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colors.primary.withAlpha(51), // 0.2
                      colors.primary.withAlpha(25), // 0.1
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.product.icon,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Nombre
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Stock con badge si es bajo
              Row(
                children: [
                  Text(
                    'Stock: ${widget.product.stock}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        ),
                  ),
                  if (widget.product.isLowStock) ...[
                    const SizedBox(width: 6),
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                        CurvedAnimation(
                          parent: _badgeController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.warning.withAlpha(38), // 0.15
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⚠️',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),

              // Precio
              Text(
                '\$${widget.product.price.toInt()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap con Hero si tiene tag
    if (widget.heroTag != null) {
      card = Hero(
        tag: widget.heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Productos demo para el onboarding
class DemoProducts {
  static const products = [
    DemoProduct(
      name: 'Arroz (Lb)',
      stock: 24,
      price: 280,
      icon: LucideIcons.wheat,
    ),
    DemoProduct(
      name: 'Aceite (1L)',
      stock: 3,
      price: 1600,
      icon: LucideIcons.droplet,
      isLowStock: true,
    ),
    DemoProduct(
      name: 'Detergente',
      stock: 15,
      price: 500,
      icon: LucideIcons.bottleWine,
    ),
    DemoProduct(
      name: 'Azúcar (Lb)',
      stock: 30,
      price: 250,
      icon: LucideIcons.cookie,
    ),
  ];
}

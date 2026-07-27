import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';

/// Página 4: Demo de turnos y cuadres con stats animados
class ShiftsDemoPage extends StatefulWidget {
  const ShiftsDemoPage({super.key});

  @override
  State<ShiftsDemoPage> createState() => _ShiftsDemoPageState();
}

class _ShiftsDemoPageState extends State<ShiftsDemoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          // Título
          Text(
            'Cobra como quieras',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.ink,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Descripción
          Text(
            'Efectivo, transferencia o mixto.\nEl cuadre se hace automáticamente.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.muted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Métodos de pago (nuevo)
          _PaymentMethodsRow(animation: _controller),

          const SizedBox(height: AppSpacing.xxl),

          // Indicador de turno activo
          _ShiftIndicator(animation: _controller),

          const SizedBox(height: AppSpacing.xxl),

          // Stats cards con números animados
          _AnimatedStatCard(
            icon: LucideIcons.dollarSign,
            label: 'Ventas del turno',
            value: 12450,
            color: colors.success,
            animation: _controller,
            delay: 0.3,
          ),
          const SizedBox(height: AppSpacing.md),
          _AnimatedStatCard(
            icon: LucideIcons.package,
            label: 'Productos vendidos',
            value: 47,
            color: colors.info,
            animation: _controller,
            delay: 0.4,
            isInteger: true,
            suffix: '',
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Footer message
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
            ),
            child: Text(
              'Controla el efectivo de cada dependiente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Métodos de pago destacados
class _PaymentMethodsRow extends StatelessWidget {
  const _PaymentMethodsRow({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PaymentMethodChip(
            icon: LucideIcons.banknote,
            label: 'Efectivo',
            color: colors.success,
          ),
          _PaymentMethodChip(
            icon: LucideIcons.smartphone,
            label: 'Transferencia',
            color: colors.info,
          ),
          _PaymentMethodChip(
            icon: LucideIcons.arrowLeftRight,
            label: 'Mixto',
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // 0.1
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: color.withAlpha(51), // 0.2
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftIndicator extends StatelessWidget {
  const _ShiftIndicator({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withAlpha(25), // 0.1
              colors.primary.withAlpha(13), // 0.05
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: colors.primary.withAlpha(38), // 0.15
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.success.withAlpha(76), // 0.3
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Turno activo: 4h 23min',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.animation,
    required this.delay,
    this.isInteger = false,
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final Animation<double> animation;
  final double delay;
  final bool isInteger;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    final delayedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, delay + 0.4, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: delayedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(delayedAnimation),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: color.withAlpha(38), // 0.15
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(25), // 0.1
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: color.withAlpha(13), // 0.05
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícono con gradient
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [color.withAlpha(51), color.withAlpha(25)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(51), // 0.2
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),

              // Valores
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                          ),
                    ),
                    const SizedBox(height: 2),
                    
                    // Número animado
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, child) {
                        String displayValue;
                        if (isInteger) {
                          displayValue = animValue.toInt().toString();
                        } else {
                          displayValue = '\$${animValue.toInt()}';
                        }
                        
                        return Text(
                          displayValue + suffix,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 28,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

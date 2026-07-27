import 'package:flutter/material.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';

/// Página 1: Bienvenida y propuesta de valor
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Ícono: elastic bounce
    _iconScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Textos: fade + slide
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono animado
          ScaleTransition(
            scale: _iconScaleAnim,
            child: AppBranding.buildAppIcon(context, size: 100),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Título
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Text(
                AppBranding.appTagline,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.ink,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Descripción
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Text(
                AppBranding.appDescription,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

          // Checkmarks animados con stagger
          ..._buildCheckmarks(),
        ],
      ),
    );
  }

  List<Widget> _buildCheckmarks() {
    final items = [
      '✓ Funciona offline',
      '✓ Control de caja diario',
      '✓ Sin papel ni Excel',
    ];

    return List.generate(items.length, (index) {
      final delay = 0.5 + (index * 0.1); // 0.5, 0.6, 0.7
      final animation = CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.2, curve: Curves.easeOut),
      );

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _CheckmarkItem(text: items[index]),
          ),
        ),
      );
    });
  }
}

class _CheckmarkItem extends StatelessWidget {
  const _CheckmarkItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          color: colors.success,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

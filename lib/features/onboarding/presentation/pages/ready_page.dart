import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';

/// Página 6: Listo para comenzar
class ReadyPage extends StatefulWidget {
  const ReadyPage({super.key});

  @override
  State<ReadyPage> createState() => _ReadyPageState();
}

class _ReadyPageState extends State<ReadyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkScaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Checkmark con elastic bounce
    _checkScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Textos fade + slide
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
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
          // Checkmark gigante animado
          ScaleTransition(
            scale: _checkScaleAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.success.withAlpha(76), // 0.3
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.lg),

          // Título
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Text(
                '¡Todo listo!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.ink,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Mensaje
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Text(
                'Ahora inicia sesión para empezar.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

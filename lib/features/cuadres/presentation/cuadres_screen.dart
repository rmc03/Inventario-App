import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../providers/cuadre_provider.dart';

class CuadresScreen extends ConsumerStatefulWidget {
  const CuadresScreen({super.key});

  @override
  ConsumerState<CuadresScreen> createState() => _CuadresScreenState();
}

class _CuadresScreenState extends ConsumerState<CuadresScreen> {

  @override
  Widget build(BuildContext context) {
    final cuadres = ref.watch(cuadreControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuadres'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
              ScreenMenuItem(
                value: 'filtrar',
                icon: Icons.filter_list_rounded,
                iconColor: context.colors.primary,
                title: 'Filtrar por fecha',
                subtitle: 'Rango de fechas',
                enabled: false,
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/admin/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: cuadres.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: context.colors.muted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay cuadres',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: context.colors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Los cuadres del día aparecerán aquí cuando los dependientes cierren su turno.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: cuadres.length,
              itemBuilder: (context, index) {
                final cuadre = cuadres[index];
                final delay = Duration(
                  milliseconds: (index * 60).clamp(0, 400),
                );
                return _AnimatedCuadreCard(
                  cuadre: cuadre,
                  delay: delay,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCuadreCard extends StatefulWidget {
  const _AnimatedCuadreCard({
    required this.cuadre,
    required this.delay,
  });

  final Cuadre cuadre;
  final Duration delay;

  @override
  State<_AnimatedCuadreCard> createState() => _AnimatedCuadreCardState();
}

class _AnimatedCuadreCardState extends State<_AnimatedCuadreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _delayController;
  late final Animation<double> _delayedFade;
  late final Animation<Offset> _delayedSlide;

  @override
  void initState() {
    super.initState();
    _delayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _delayedFade = CurvedAnimation(
      parent: _delayController,
      curve: Curves.easeOutCubic,
    );
    _delayedSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _delayController,
      curve: Curves.easeOutCubic,
    ));
    _startDelayed();
  }

  Future<void> _startDelayed() async {
    await Future.delayed(widget.delay);
    if (mounted) _delayController.forward();
  }

  @override
  void dispose() {
    _delayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _delayController,
      builder: (context, child) {
        return Opacity(
          opacity: _delayedFade.value,
          child: Transform.translate(
            offset: _delayedSlide.value * 12,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PressScaleCard(
          onTap: () => context.push('/admin/cuadres/${widget.cuadre.id}'),
          child: Card(
            key: ValueKey(widget.cuadre.id),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(
                compactDateFormatter.format(widget.cuadre.fechaTurno),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                widget.cuadre.dependienteNombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _AnimatedEstadoBadge(
                estado: widget.cuadre.estado,
                animationDelay: widget.delay + const Duration(milliseconds: 200),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressScaleCard extends StatefulWidget {
  const _PressScaleCard({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressScaleCard> createState() => _PressScaleCardState();
}

class _PressScaleCardState extends State<_PressScaleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        Haptics.tap(context);
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _AnimatedEstadoBadge extends StatefulWidget {
  const _AnimatedEstadoBadge({
    required this.estado,
    this.animationDelay = Duration.zero,
  });

  final CuadreEstado estado;
  final Duration animationDelay;

  @override
  State<_AnimatedEstadoBadge> createState() => _AnimatedEstadoBadgeState();
}

class _AnimatedEstadoBadgeState extends State<_AnimatedEstadoBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _startDelayed();
  }

  Future<void> _startDelayed() async {
    await Future.delayed(widget.animationDelay);
    if (mounted) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedEstadoBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estado != widget.estado) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (widget.estado) {
      CuadreEstado.aprobado => context.colors.success,
      CuadreEstado.rechazado => context.colors.danger,
      CuadreEstado.pendiente => context.colors.warning,
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            widget.estado.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

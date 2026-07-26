import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/accessibility_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/pago.dart';
import '../../../shared/models/venta.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../../../shared/widgets/shift_summary_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../../ventas/providers/venta_provider.dart';
import '../providers/turno_provider.dart';

class MiTurnoScreen extends ConsumerWidget {
  const MiTurnoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turno = ref.watch(turnoControllerProvider);
    final usuario = ref.watch(authControllerProvider).user;

    if (turno.estaActivo) {
      return const _TurnoActivoView();
    } else if (turno.cuadreEnviadoHoy) {
      return const _CuadreEnviadoView();
    } else {
      // Verificar si hay un cuadre aprobado hoy
      final cuadres = ref.watch(cuadreControllerProvider);
      final hoy = DateTime.now();
      final cuadreAprobadoHoy = usuario != null
          ? cuadres.where((c) =>
              c.dependienteId == usuario.id &&
              c.estado == CuadreEstado.aprobado &&
              _isSameDay(c.fechaTurno, hoy)).firstOrNull
          : null;

      if (cuadreAprobadoHoy != null) {
        return _CuadreAprobadoView(cuadre: cuadreAprobadoHoy);
      } else {
        return const _SinTurnoView();
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─── Animated helpers ─────────────────────────────────────────────────────────

/// Counts from 0 to [end] with easeOutCubic, respecting Reduce Motion.
class _AnimatedNumber extends StatefulWidget {
  const _AnimatedNumber({
    required this.end,
    required this.style,
  });

  final double end;
  final TextStyle style;

  @override
  State<_AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<_AnimatedNumber>
    with SingleTickerProviderStateMixin {
  bool _animInitialized = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addListener(() {
      setState(() => _displayed = _animation.value * widget.end);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      _controller.duration = context.animationDuration(const Duration(milliseconds: 800));
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      final from = _animation.value * oldWidget.end;
      _animation = Tween<double>(begin: from, end: widget.end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = formatCurrency(_displayed);
    return Text(text, style: widget.style);
  }
}

/// Gentle floating pulse for empty-state icons.
class _FloatingPulse extends StatefulWidget {
  const _FloatingPulse({required this.child});

  final Widget child;

  @override
  State<_FloatingPulse> createState() => _FloatingPulseState();
}

class _FloatingPulseState extends State<_FloatingPulse>
    with SingleTickerProviderStateMixin {
  bool _animInitialized = false;
  late AnimationController _controller;
  late Animation<double> _float;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _float = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      _controller.duration = context.animationDuration(const Duration(milliseconds: 2800));
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.scale(scale: _pulse.value, child: child),
      ),
    );
  }
}

// ─── Estado 1: Sin turno activo ───────────────────────────────────────────────

class _SinTurnoView extends ConsumerStatefulWidget {
  const _SinTurnoView();

  @override
  ConsumerState<_SinTurnoView> createState() => _SinTurnoViewState();
}

class _SinTurnoViewState extends ConsumerState<_SinTurnoView>
    with TickerProviderStateMixin {
  bool _isStarting = false;
  bool _animInitialized = false;
  late AnimationController _entranceCtrl;
  late Animation<double> _iconFade;
  late Animation<Offset> _iconSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _iconFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _iconSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    ));

    _textFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    ));

    _buttonFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      _entranceCtrl.duration = context.animationDuration(const Duration(milliseconds: 500));
      _entranceCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _iniciarTurnoConAnimacion() async {
    if (_isStarting) return;

    setState(() => _isStarting = true);
    Haptics.confirm(context);

    // Pausa breve para mostrar el loading
    await Future.delayed(const Duration(milliseconds: 300));

    // Iniciar turno
    ref.read(turnoControllerProvider.notifier).iniciarTurno();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
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
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/dependiente/configuracion');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _iconFade,
                    child: SlideTransition(
                      position: _iconSlide,
                      child: _FloatingPulse(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                context.colors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Icon(
                              Icons.work_outline_rounded,
                              size: 56,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        compactDateFormatter.format(DateTime.now()),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _isStarting
                          ? 'Iniciando turno...'
                          : 'Aún no has iniciado tu turno',
                      key: ValueKey(_isStarting),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.colors.muted,
                            fontWeight:
                                _isStarting ? FontWeight.w600 : FontWeight.w400,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: SlideTransition(
                      position: _buttonSlide,
                      child: SizedBox(
                        height: 58,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isStarting ? null : _iniciarTurnoConAnimacion,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isStarting
                                ? SizedBox(
                                    key: const ValueKey('loading'),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.play_arrow_rounded,
                                    key: ValueKey('icon'),
                                  ),
                          ),
                          label: Text(
                              _isStarting ? 'Iniciando...' : 'Iniciar turno'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Estado 2: Turno activo ───────────────────────────────────────────────────

class _TurnoActivoView extends ConsumerStatefulWidget {
  const _TurnoActivoView();

  @override
  ConsumerState<_TurnoActivoView> createState() => _TurnoActivoViewState();
}

class _TurnoActivoViewState extends ConsumerState<_TurnoActivoView>
    with TickerProviderStateMixin {
  bool _animInitialized = false;
  bool _isNavigatingToNuevaVenta = false;
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;

  int _previousVentaCount = 0;
  String? _lastVentaId;  // Track the ID of the most recent sale
  late AnimationController _pulseCtrl;
  late AnimationController _newVentaCtrl;
  late Animation<double> _newVentaScale;
  late Animation<double> _newVentaGlow;
  late Animation<double> _newVentaFade;
  late Animation<Offset> _newVentaSlide;

  static const _itemCount = 4;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _newVentaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Inicializar _lastVentaId ANTES del primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastVentaId == null) {
        final ventas = ref.read(ventasDelTurnoProvider);
        if (ventas.isNotEmpty) {
          setState(() {
            _lastVentaId = ventas.first.id;
          });
        }
      }
    });

    // Animaciones para nueva venta (simplificadas para evitar errores)
    _newVentaScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _newVentaCtrl,
        curve: Curves.easeOutBack,
      ),
    );

    _newVentaGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _newVentaCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _newVentaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _newVentaCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _newVentaSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _newVentaCtrl,
      curve: Curves.easeOutCubic,
    ));

    _itemFades = List.generate(_itemCount, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });
    _itemSlides = List.generate(_itemCount, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      _entranceCtrl.duration = context.animationDuration(const Duration(milliseconds: 500));
      _entranceCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _newVentaCtrl.dispose();
    super.dispose();
  }

  void _nuevaVentaConAnimacion() async {
    if (_isNavigatingToNuevaVenta) return;
    
    setState(() => _isNavigatingToNuevaVenta = true);
    Haptics.tap(context);

    await Future.delayed(const Duration(milliseconds: 150));
    
    if (mounted) {
      setState(() => _isNavigatingToNuevaVenta = false);
      context.push('/dependiente/turno/nueva-venta');
    }
  }

  Widget _staggeredItem(int index, Widget child) {
    return FadeTransition(
      opacity: _itemFades[index],
      child: SlideTransition(
        position: _itemSlides[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turno = ref.watch(turnoControllerProvider);
    final ventas = ref.watch(ventasDelTurnoProvider);
    final totalTurno = ventas.fold(0.0, (sum, v) => sum + v.total);
    final totalArticulos = ventas.fold(0, (sum, v) => sum + v.totalUnidades);

    // Detectar nueva venta y activar animación
    if (ventas.isNotEmpty && ventas.first.id != _lastVentaId) {
      final isNewSale = _lastVentaId != null;
      _lastVentaId = ventas.first.id;
      
      if (isNewSale) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pulseCtrl.forward(from: 0);
            _newVentaCtrl.forward(from: 0);
            Haptics.confirm(context);
          }
        });
      } else {
        // Para la primera venta, completar animación instantáneamente
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _newVentaCtrl.value = 1.0;
          }
        });
      }
    }

    if (ventas.length > _previousVentaCount && _previousVentaCount > 0) {
      _previousVentaCount = ventas.length;
    } else {
      _previousVentaCount = ventas.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'cerrar',
                icon: Icons.logout_rounded,
                iconColor: context.colors.danger,
                title: 'Cerrar turno',
                subtitle: 'Finaliza tu jornada',
              ),
              ScreenMenuItem(
                value: 'ajustes',
                icon: Icons.settings_rounded,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'cerrar':
                  Haptics.confirm(context);
                  context.push('/dependiente/turno/resumen');
                  break;
                case 'ajustes':
                  context.push('/dependiente/configuracion');
                  break;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card resumen con badge, stats y cerrar turno
                _staggeredItem(
                  0,
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      final t = _pulseCtrl.value;
                      final scale = 1.0 + (0.02 * (t < 0.5 ? t * 2 : 2.0 * (1.0 - t)));
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        12,
                        AppSpacing.xl,
                        8,
                      ),
                      child: ShiftSummaryCard(
                        totalVentas: totalTurno,
                        cantidadVentas: ventas.length,
                        cantidadUnidades: totalArticulos,
                        activo: true,
                        horaInicio: turno.horaInicio,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      0,
                    ),
                    children: [
                      if (ventas.isNotEmpty) ...[
                        // Historial de ventas
                        _staggeredItem(
                          1,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Historial de ventas',
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              TextButton(
                                onPressed: () =>
                                    _showAllVentasSheet(context, ventas),
                                child: const Text('Ver todas'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(
                          ventas.length > 5 ? 5 : ventas.length,
                          (i) {
                            final venta = ventas[i];
                            return _staggeredItem(
                              2,
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: i == 0 
                                  ? _AnimatedVentaCard(
                                      key: ValueKey('animated_${venta.id}'),
                                      venta: venta,
                                      scaleAnimation: _newVentaScale,
                                      glowAnimation: _newVentaGlow,
                                      fadeAnimation: _newVentaFade,
                                      slideAnimation: _newVentaSlide,
                                    )
                                  : _VentaCard(
                                      key: ValueKey('normal_${venta.id}'),
                                      venta: venta,
                                    ),
                              ),
                            );
                          },
                        ),
                        // Indicador de más ventas
                        if (ventas.length > 5)
                          _staggeredItem(
                            2,
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.md),
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _showAllVentasSheet(context, ventas),
                                  icon: const Icon(
                                      Icons.expand_more_rounded, size: 20),
                                  label: Text(
                                    'Ver ${ventas.length - 5} ventas más',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],

                      if (ventas.isEmpty)
                        _staggeredItem(1, const _EmptyItems()),
                    ],
                  ),
                ),
                // Botón nueva venta (fijo al fondo)
                _staggeredItem(
                  3,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isNavigatingToNuevaVenta ? null : _nuevaVentaConAnimacion,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isNavigatingToNuevaVenta
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add_rounded, size: 22, key: ValueKey('icon')),
                        ),
                        label: Text(
                          _isNavigatingToNuevaVenta ? 'Cargando...' : 'Nueva venta',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un bottom sheet con todas las ventas del turno
  /// Siguiendo UI/UX Pro Max §2 Touch & Interaction con lista scrollable
  void _showAllVentasSheet(BuildContext context, List<Venta> ventas) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Todas las ventas',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${ventas.length} ${ventas.length == 1 ? 'venta' : 'ventas'} • ${formatCurrency(ventas.fold(0.0, (sum, v) => sum + v.total))}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.colors.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lista de ventas
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: ventas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _VentaCard(venta: ventas[index]);
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
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingPulse(
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: context.colors.muted.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sin ventas aún',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca en "Nueva venta" para atender a un cliente.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VentaCard extends StatelessWidget {
  const _VentaCard({super.key, required this.venta});

  final Venta venta;

  @override
  Widget build(BuildContext context) {
    // Detectar el método de pago (mixto si hay más de un tipo de pago)
    MetodoPago? metodoPago;
    if (venta.pagos.isNotEmpty) {
      if (venta.pagos.length > 1) {
        metodoPago = MetodoPago.mixto;
      } else {
        metodoPago = venta.pagos.first.metodo;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.line,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _VentaCardContent(venta: venta, metodoPago: metodoPago),
    );
  }
}

/// Versión animada de _VentaCard para ventas recién agregadas
class _AnimatedVentaCard extends StatelessWidget {
  const _AnimatedVentaCard({
    super.key,
    required this.venta,
    required this.scaleAnimation,
    required this.glowAnimation,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  final Venta venta;
  final Animation<double> scaleAnimation;
  final Animation<double> glowAnimation;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  @override
  Widget build(BuildContext context) {
    // Detectar el método de pago (mixto si hay más de un tipo de pago)
    MetodoPago? metodoPago;
    if (venta.pagos.isNotEmpty) {
      if (venta.pagos.length > 1) {
        metodoPago = MetodoPago.mixto;
      } else {
        metodoPago = venta.pagos.first.metodo;
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, glowAnimation, fadeAnimation, slideAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideAnimation.value.dy * 30),
            child: Transform.scale(
              scale: scaleAnimation.value.clamp(0.5, 1.5),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color.lerp(
                      context.colors.line,
                      context.colors.ink.withValues(alpha: 0.15),
                      (glowAnimation.value * 0.8).clamp(0.0, 1.0),
                    )!,
                    width: (1 + (glowAnimation.value * 1.0).clamp(0.0, 1.5)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.ink.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    // Sombra sutil para destacar
                    if (glowAnimation.value > 0.1)
                      BoxShadow(
                        color: context.colors.ink.withValues(
                          alpha: (glowAnimation.value * 0.08).clamp(0.0, 1.0),
                        ),
                        blurRadius: 16 * glowAnimation.value.clamp(0.0, 1.0),
                        spreadRadius: 1 * glowAnimation.value.clamp(0.0, 1.0),
                      ),
                  ],
                ),
                child: _VentaCardContent(venta: venta, metodoPago: metodoPago),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Contenido compartido entre _VentaCard y _AnimatedVentaCard
class _VentaCardContent extends StatelessWidget {
  const _VentaCardContent({
    required this.venta,
    required this.metodoPago,
  });

  final Venta venta;
  final MetodoPago? metodoPago;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.push('/dependiente/turno/venta/${venta.id}', extra: venta),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Ícono con gradiente
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colors.primary.withValues(alpha: 0.15),
                      context.colors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_cart_rounded,
                  color: context.colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Información de la venta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta a las ${timeFormatter.format(venta.fecha)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Badge de artículos
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 12,
                                color: context.colors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                articulosLabel(venta.totalUnidades),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge de método de pago (si aplica)
                        if (metodoPago != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: metodoPago == MetodoPago.efectivo
                                  ? context.colors.success.withValues(alpha: 0.08)
                                  : metodoPago == MetodoPago.transferencia
                                      ? context.colors.warning.withValues(alpha: 0.08)
                                      : context.colors.info.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  metodoPago == MetodoPago.efectivo
                                      ? Icons.payments_rounded
                                      : metodoPago == MetodoPago.transferencia
                                          ? Icons.credit_card_rounded
                                          : Icons.sync_alt_rounded,
                                  size: 12,
                                  color: metodoPago == MetodoPago.efectivo
                                      ? context.colors.success
                                      : metodoPago == MetodoPago.transferencia
                                          ? context.colors.warning
                                          : context.colors.info,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  metodoPago == MetodoPago.efectivo
                                      ? 'Efectivo'
                                      : metodoPago == MetodoPago.transferencia
                                          ? 'Transferencia'
                                          : 'Mixto',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: metodoPago == MetodoPago.efectivo
                                            ? context.colors.success
                                            : metodoPago == MetodoPago.transferencia
                                                ? context.colors.warning
                                                : context.colors.info,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Precio y chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(venta.total),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Estado 3: Cuadre enviado ─────────────────────────────────────────────────

class _CuadreEnviadoView extends ConsumerStatefulWidget {
  const _CuadreEnviadoView();

  @override
  ConsumerState<_CuadreEnviadoView> createState() =>
      _CuadreEnviadoViewState();
}

class _CuadreEnviadoViewState extends ConsumerState<_CuadreEnviadoView>
    with SingleTickerProviderStateMixin {
  bool _animInitialized = false;
  late AnimationController _ctrl;
  late Animation<double> _bannerFade;
  late Animation<Offset> _bannerSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bannerFade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      _ctrl.duration = context.animationDuration(const Duration(milliseconds: 500));
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ventas = ref.watch(ventasDelTurnoProvider);
    final total = ventas.fold(0.0, (sum, v) => sum + v.total);
    final totalUnidades = ventas.fold(0, (sum, v) => sum + v.totalUnidades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
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
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/dependiente/configuracion');
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
            child: Column(
              children: [
                // ── Status Banner ──
                FadeTransition(
                  opacity: _bannerFade,
                  child: SlideTransition(
                    position: _bannerSlide,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colors.success.withValues(alpha: 0.12),
                            context.colors.success.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.success.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colors.success
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 28,
                                  color: context.colors.success,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cuadre enviado',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.success,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pendiente de revisión',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: context.colors.ink
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.colors.surface
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: context.colors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Puedes seguir vendiendo. El cuadre se actualizará automáticamente.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: context.colors.muted,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Resumen actual ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ShiftSummaryCard(
                    totalVentas: total,
                    cantidadVentas: ventas.length,
                    cantidadUnidades: totalUnidades,
                    activo: false,
                    horaInicio:
                        ref.watch(turnoControllerProvider).horaInicio,
                    showEditBadge: true,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Historial de ventas ──
                Expanded(
                  child: ventas.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _FloatingPulse(
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: context.colors.muted
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Cuadre enviado sin ventas',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Toca "Continuar vendiendo" para\natender más clientes.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ventas del turno',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                if (ventas.length > 3)
                                  TextButton(
                                    onPressed: () =>
                                        _showAllVentasSheet(
                                            context, ventas),
                                    child: const Text('Ver todas'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...List.generate(
                              ventas.length > 3 ? 3 : ventas.length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child:
                                    _VentaCard(venta: ventas[i]),
                              ),
                            ),
                            if (ventas.length > 3)
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4),
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _showAllVentasSheet(
                                            context, ventas),
                                    icon: const Icon(
                                        Icons.expand_more_rounded,
                                        size: 20),
                                    label: Text(
                                      'Ver ${ventas.length - 3} ventas más',
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // ── Botón continuar vendiendo ──
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Haptics.confirm(context);
                            ref
                                .read(turnoControllerProvider
                                    .notifier)
                                .reabrirTurno();
                          },
                          icon:
                              const Icon(Icons.add_rounded, size: 22),
                          label: const Text(
                            'Continuar vendiendo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'El cuadre se actualizará con las nuevas ventas',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.colors.muted,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllVentasSheet(BuildContext context, List<Venta> ventas) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Todas las ventas',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${ventas.length} ${ventas.length == 1 ? 'venta' : 'ventas'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: ventas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                       return _VentaCard(venta: ventas[index]);
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
}

// ─── Estado 4: Cuadre aprobado hoy ─────────────────────────────────────────────

class _CuadreAprobadoView extends ConsumerStatefulWidget {
  const _CuadreAprobadoView({required this.cuadre});

  final Cuadre cuadre;

  @override
  ConsumerState<_CuadreAprobadoView> createState() =>
      _CuadreAprobadoViewState();
}

class _CuadreAprobadoViewState extends ConsumerState<_CuadreAprobadoView>
    with SingleTickerProviderStateMixin {
  bool _animInitialized = false;
  late AnimationController _ctrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _checkFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    _statsFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      _ctrl.duration = context.animationDuration(const Duration(milliseconds: 600));
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cuadre = widget.cuadre;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi turno'),
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
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/dependiente/configuracion');
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
            child: Column(
              children: [
                const Spacer(flex: 2),

                FadeTransition(
                  opacity: _checkFade,
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.colors.success.withValues(alpha: 0.2),
                            context.colors.success.withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Icon(
                          Icons.verified_rounded,
                          size: 72,
                          color: context.colors.success,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Text(
                      '¡Buen trabajo, ${cuadre.dependienteNombre.split(' ').first}!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Text(
                      'Tu cuadre fue aprobado',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.colors.success,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    compactDateFormatter.format(cuadre.fechaTurno),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.muted,
                        ),
                  ),
                ),

                const SizedBox(height: 32),

                FadeTransition(
                  opacity: _statsFade,
                  child: SlideTransition(
                    position: _statsSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                label: 'Ventas',
                                value: '${cuadre.ventas.length}',
                                icon: Icons.receipt_long_rounded,
                                color: context.colors.primary,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: context.colors.line,
                            ),
                            Expanded(
                              child: _StatItem(
                                label: 'Unidades',
                                value: '${cuadre.totalSalidas}',
                                icon: Icons.inventory_2_rounded,
                                color: context.colors.warning,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: context.colors.line,
                            ),
                            Expanded(
                              child: _StatItem(
                                label: 'Total',
                                value: formatCurrency(cuadre.valorTotal),
                                icon: Icons.payments_rounded,
                                color: context.colors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    height: 58,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Haptics.confirm(context);
                        ref
                            .read(turnoControllerProvider.notifier)
                            .iniciarTurno();
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Iniciar nuevo turno',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.muted,
          ),
        ),
      ],
    );
  }
}



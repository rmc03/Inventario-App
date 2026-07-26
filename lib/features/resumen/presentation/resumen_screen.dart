import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/screen_popup_menu.dart';
import '../data/resumen_repository.dart';
import '../providers/resumen_provider.dart';

/// Duración base para animaciones de entrada (iOS/Android native timing).
const _kEntranceDuration = Duration(milliseconds: 400);
const _kEntranceCurve = Curves.easeOutCubic;
const _kStaggerInterval = Duration(milliseconds: 80);
const _kFeedbackDuration = Duration(milliseconds: 150);

/// Pantalla de resumen del Admin: primer tab y landing al autenticar.
/// Muestra ventas, productos más vendidos, alertas de stock y estado de cuadres.
class ResumenScreen extends ConsumerWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenState = ref.watch(resumenControllerProvider);
    final periodo = ref.watch(periodoResumenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          ScreenPopupMenu(
            items: [
              ScreenMenuItem(
                value: 'ajustes',
                icon: LucideIcons.settings,
                iconColor: context.colors.muted,
                title: 'Ajustes',
                subtitle: 'Preferencias de la app',
              ),
            ],
            onSelected: (value) {
              if (value == 'ajustes') {
                context.push('/admin/configuracion');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(resumenControllerProvider.notifier).refresh();
        },
        child: _ResumenBody(
          state: resumenState,
          periodo: periodo,
          onRetry: () =>
              ref.read(resumenControllerProvider.notifier).refresh(),
          onPeriodoChanged: (nuevoPeriodo) {
            ref
                .read(resumenControllerProvider.notifier)
                .setPeriodo(nuevoPeriodo);
          },
        ),
      ),
    );
  }
}

/// Body principal que maneja loading, error y datos.
class _ResumenBody extends StatefulWidget {
  const _ResumenBody({
    required this.state,
    required this.periodo,
    required this.onRetry,
    required this.onPeriodoChanged,
  });

  final ResumenState state;
  final PeriodoResumen periodo;
  final VoidCallback onRetry;
  final ValueChanged<PeriodoResumen> onPeriodoChanged;

  @override
  State<_ResumenBody> createState() => _ResumenBodyState();
}

class _ResumenBodyState extends State<_ResumenBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kEntranceDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _kEntranceCurve),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: _kEntranceCurve),
    );

    // Iniciar animación cuando hay datos
    if (!widget.state.isLoading && !widget.state.hasError) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_ResumenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar transición cuando cambian los datos
    if (oldWidget.state.isLoading && !widget.state.isLoading) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (widget.state.hasError) {
      return _buildErrorState(context);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildDataContent(context, widget.state.datos, widget.periodo),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonTile(height: 48),
          SizedBox(height: AppSpacing.xl),
          SkeletonTile(height: 100),
          SizedBox(height: AppSpacing.xl),
          SkeletonTile(height: 60),
          SizedBox(height: AppSpacing.lg),
          SkeletonTile(height: 52),
          SizedBox(height: AppSpacing.lg),
          SkeletonTile(height: 52),
          SizedBox(height: AppSpacing.lg),
          SkeletonTile(height: 200),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 48,
              color: context.colors.danger,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No se pudo cargar el resumen',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              widget.state.errorMessage ?? 'Error desconocido',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            Semantics(
              label: 'Reintentar carga del resumen',
              button: true,
              child: OutlinedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataContent(
    BuildContext context,
    DatosResumen datos,
    PeriodoResumen periodo,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodoSelector(
            periodoActual: periodo,
            onPeriodoChanged: widget.onPeriodoChanged,
          ),
          SizedBox(height: AppSpacing.xl),

          _HeroStats(
            ventasTotales: datos.ventasTotales,
            unidadesVendidas: datos.unidadesVendidas,
            deltaVentas: datos.deltaVentas,
            deltaUnidades: datos.deltaUnidades,
            periodo: periodo,
          ),
          SizedBox(height: AppSpacing.xxl),

          _TopProductosCard(productos: datos.topProductos),
          SizedBox(height: AppSpacing.lg),

          _AlertasOperacionales(
            productosStockBajo: datos.productosStockBajo,
            cuadresPendientes: datos.cuadresPendientes,
          ),
          SizedBox(height: AppSpacing.lg),

          if (datos.tendenciaVentas.isNotEmpty)
            _TendenciaVentasCard(
              datos: datos.tendenciaVentas,
              ventasTotales: datos.ventasTotales,
              periodo: periodo,
            ),
        ],
      ),
    );
  }
}

/// Selector de período (Hoy / Esta semana / Este mes) con feedback táctil.
class _PeriodoSelector extends StatelessWidget {
  const _PeriodoSelector({
    required this.periodoActual,
    required this.onPeriodoChanged,
  });

  final PeriodoResumen periodoActual;
  final ValueChanged<PeriodoResumen> onPeriodoChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -8 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Selector de período: ${periodoActual.label}',
        child: SegmentedButton<PeriodoResumen>(
          segments: PeriodoResumen.values.map((periodo) {
            return ButtonSegment<PeriodoResumen>(
              value: periodo,
              label: Text(
                periodo.label,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            );
          }).toList(),
          selected: {periodoActual},
          onSelectionChanged: (selection) {
            onPeriodoChanged(selection.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero stats — números grandes y destacados con delta de comparación.
class _HeroStats extends StatelessWidget {
  const _HeroStats({
    required this.ventasTotales,
    required this.unidadesVendidas,
    required this.deltaVentas,
    required this.deltaUnidades,
    required this.periodo,
  });

  final double ventasTotales;
  final int unidadesVendidas;
  final double? deltaVentas;
  final double? deltaUnidades;
  final PeriodoResumen periodo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnimatedHeroStatCard(
            label: 'Ventas totales',
            value: ventasTotales,
            icon: LucideIcons.dollarSign,
            color: context.colors.success,
            delta: deltaVentas,
            formatter: (val) => NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 0,
            ).format(val),
            delay: Duration.zero,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AnimatedHeroStatCard(
            label: 'Unidades vendidas',
            value: unidadesVendidas.toDouble(),
            icon: LucideIcons.shoppingBag,
            color: context.colors.info,
            delta: deltaUnidades,
            formatter: (val) => val.toInt().toString(),
            delay: _kStaggerInterval,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de estadística hero animada con conteo progresivo.
class _AnimatedHeroStatCard extends StatefulWidget {
  const _AnimatedHeroStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.formatter,
    required this.delay,
    this.delta,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final double? delta;
  final String Function(double) formatter;
  final Duration delay;

  @override
  State<_AnimatedHeroStatCard> createState() => _AnimatedHeroStatCardState();
}

class _AnimatedHeroStatCardState extends State<_AnimatedHeroStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _countAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Delay inicial antes de iniciar
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedHeroStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // Animar cambio de valor
      _countAnimation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Semantics(
        label: '${widget.label}: ${widget.formatter(widget.value)}'
            '${widget.delta != null ? ', cambio ${_formatDelta(widget.delta!)}' : ''}',
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadii.mdBorder,
            border: isDark ? Border.all(
              color: context.colors.line,  // Border gris simple, sin color
              width: 1,
            ) : null,
            boxShadow: AppShadows.subtle,  // Sombra sutil estándar, sin glows
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg + 4,
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: AppAlphas.fill),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: widget.color,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.md),
                AnimatedBuilder(
                  animation: _countAnimation,
                  builder: (context, child) {
                    return Text(
                      widget.formatter(_countAnimation.value),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: widget.color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            height: 1,
                          ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                if (widget.delta != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 8 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _DeltaIndicator(delta: widget.delta!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDelta(double value) {
    final pct = (value * 100).round();
    return value >= 0 ? '+$pct%' : '$pct%';
  }
}

/// Indicador de cambio porcentual con flecha y color.
class _DeltaIndicator extends StatelessWidget {
  const _DeltaIndicator({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final isNeutral = delta == 0;
    final color = isNeutral
        ? context.colors.muted
        : isPositive
            ? context.colors.success
            : context.colors.danger;
    final pct = (delta * 100).round();
    final text = isNeutral
        ? 'Sin cambio'
        : '${isPositive ? '+' : ''}$pct% vs anterior';

    return Semantics(
      label: text,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppAlphas.fill),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNeutral
                  ? LucideIcons.minus
                  : isPositive
                      ? LucideIcons.trendingUp
                      : LucideIcons.trendingDown,
              size: 14,
              color: color,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de top productos vendidos.
class _TopProductosCard extends StatelessWidget {
  const _TopProductosCard({required this.productos});

  final List<ProductoVendido> productos;

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return _buildEmptyState(context);
    }

    final maxUnidades =
        productos.map((p) => p.unidades).reduce((a, b) => a > b ? a : b);

    return Semantics(
      label: 'Productos más vendidos: ${productos.length} productos',
      child: Card(
        elevation: 0,
        color: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.chartLine,
                    color: context.colors.primary,
                    size: 22,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Más vendidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary
                          .withValues(alpha: AppAlphas.fill),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      '${productos.length} ${productos.length == 1 ? 'producto' : 'productos'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              ...productos.asMap().entries.map((entry) {
                final index = entry.key;
                final producto = entry.value;
                final isLast = index == productos.length - 1;
                return Column(
                  children: [
                    _TopProductoItem(
                      ranking: index + 1,
                      nombre: producto.nombre,
                      unidades: producto.unidades,
                      valor: producto.valorTotal,
                      isFirst: index == 0,
                      progress: producto.unidades / maxUnidades,
                      index: index,
                    ),
                    if (!isLast) ...[
                      SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: EdgeInsets.only(left: 48), // 32 (badge) + 16 (spacing)
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: context.colors.line
                              .withValues(alpha: AppAlphas.fillStrong),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.chartLine,
                    color: context.colors.primary,
                    size: 22,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Más vendidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl + AppSpacing.sm),
              Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, iconValue, child) {
                    return Transform.scale(
                      scale: 0.7 + (0.3 * iconValue),
                      child: Opacity(
                        opacity: iconValue,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.package,
                        size: 48,
                        color: context.colors.muted.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'No hay ventas en este período',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individual del top productos con entrada escalonada.
class _TopProductoItem extends StatelessWidget {
  const _TopProductoItem({
    required this.ranking,
    required this.nombre,
    required this.unidades,
    required this.valor,
    required this.isFirst,
    required this.progress,
    required this.index,
  });

  final int ranking;
  final String nombre;
  final int unidades;
  final double valor;
  final bool isFirst;
  final double progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 60)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Puesto $ranking: $nombre, $unidades unidades, '
            '${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(valor)}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RankingBadge(ranking: ranking, isFirst: isFirst),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isFirst ? FontWeight.w700 : FontWeight.w600,
                          fontSize: isFirst ? 16 : 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.shoppingBag,
                        size: 14,
                        color: context.colors.info,
                      ),
                      SizedBox(width: AppSpacing.xs / 2),
                      Text(
                        '$unidades unidades',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.info,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.colors.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(valor),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _AnimatedProgressBar(
                    progress: progress,
                    color: isFirst ? context.colors.primary : context.colors.info,
                    backgroundColor: context.colors.surfaceSecondary,
                    delay: Duration(milliseconds: 200 + (index * 60)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de ranking con medalla para #1.
class _RankingBadge extends StatelessWidget {
  const _RankingBadge({required this.ranking, required this.isFirst});

  final int ranking;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isFirst
            ? context.colors.primary
            : context.colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: context.colors.primary
                      .withValues(alpha: AppAlphas.fillStrong),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: isFirst
          ? Icon(
              LucideIcons.trophy,
              size: 18,
              color: context.colors.surface,
            )
          : Text(
              '$ranking',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
            ),
    );
  }
}

/// Barra de progreso animada con fill progresivo.
class _AnimatedProgressBar extends StatefulWidget {
  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.delay,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final Duration delay;

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progreso: ${(widget.progress * 100).round()}%',
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _animation.value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Alertas operacionales en grid.
class _AlertasOperacionales extends StatelessWidget {
  const _AlertasOperacionales({
    required this.productosStockBajo,
    required this.cuadresPendientes,
  });

  final int productosStockBajo;
  final int cuadresPendientes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AlertaCard(
          icon: productosStockBajo > 0
              ? LucideIcons.alertTriangle
              : LucideIcons.checkCircle,
          title: productosStockBajo > 0 ? 'Stock bajo' : 'Stock OK',
          subtitle: productosStockBajo > 0
              ? '$productosStockBajo ${productosStockBajo == 1 ? 'producto necesita' : 'productos necesitan'} reposición'
              : 'Todos los productos con stock suficiente',
          color: productosStockBajo > 0
              ? context.colors.danger
              : context.colors.success,
          hasAction: productosStockBajo > 0,
          onTap: productosStockBajo > 0
              ? () => context.push('/admin/inventario')
              : null,
        ),
        SizedBox(height: AppSpacing.md),
        _AlertaCard(
          icon: cuadresPendientes > 0
              ? LucideIcons.clock
              : LucideIcons.checkCircle,
          title: cuadresPendientes > 0
              ? 'Cuadres pendientes'
              : 'Cuadres al día',
          subtitle: cuadresPendientes > 0
              ? '$cuadresPendientes ${cuadresPendientes == 1 ? 'cuadre requiere' : 'cuadres requieren'} revisión'
              : 'No hay cuadres esperando aprobación',
          color: cuadresPendientes > 0
              ? context.colors.warning
              : context.colors.success,
          hasAction: cuadresPendientes > 0,
          onTap: cuadresPendientes > 0
              ? () => context.push('/admin/cuadres')
              : null,
        ),
      ],
    );
  }
}

/// Tarjeta de alerta operacional con micro-interacción táctil.
class _AlertaCard extends StatefulWidget {
  const _AlertaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.hasAction,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool hasAction;
  final VoidCallback? onTap;

  @override
  State<_AlertaCard> createState() => _AlertaCardState();
}

class _AlertaCardState extends State<_AlertaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: _kFeedbackDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.hasAction) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.hasAction) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.hasAction) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Semantics(
        label: '${widget.title}: ${widget.subtitle}',
        button: widget.hasAction,
        child: Card(
          elevation: 0,
          color: widget.hasAction
              ? widget.color.withValues(alpha: AppAlphas.fill)
              : context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.mdBorder,
            side: widget.hasAction
                ? BorderSide.none
                : BorderSide(color: context.colors.line, width: 1),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            borderRadius: AppRadii.mdBorder,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: (1 - value) * 0.2,
                        child: Transform.scale(
                          scale: 0.7 + (0.3 * value),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: widget.hasAction
                            ? widget.color.withValues(alpha: AppAlphas.fillStrong)
                            : widget.color.withValues(alpha: AppAlphas.fill),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: widget.color,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.hasAction) ...[
                    SizedBox(width: AppSpacing.sm),
                    Icon(
                      LucideIcons.arrowRight,
                      color: widget.color,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de tendencia de ventas — se adapta al período seleccionado.
class _TendenciaVentasCard extends StatelessWidget {
  const _TendenciaVentasCard({
    required this.datos,
    required this.ventasTotales,
    required this.periodo,
  });

  final List<double> datos;
  final double ventasTotales;
  final PeriodoResumen periodo;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SizedBox.shrink();

    final max = datos.reduce((a, b) => a > b ? a : b);
    final min = datos.reduce((a, b) => a < b ? a : b);
    final promedio = datos.reduce((a, b) => a + b) / datos.length;

    final labels = _getLabels(periodo);

    return Semantics(
      label: 'Tendencia de ventas: promedio '
          '${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(promedio)}',
      child: Card(
        elevation: 0,
        color: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.chartLine,
                    color: context.colors.primary,
                    size: 22,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tendencia de ventas',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                  ),
                        ),
                        SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          _getPeriodLabel(periodo),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: context.colors.muted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 120,
                child: _SparklineConLabels(
                  datos: datos,
                  labels: labels,
                  color: context.colors.primary,
                  backgroundColor: context.colors.surfaceSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Container(
                height: 1,
                color: context.colors.line,
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Promedio',
                      value: NumberFormat.currency(
                        symbol: '\$',
                        decimalDigits: 0,
                      ).format(promedio),
                      color: context.colors.primary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.colors.line,
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Mejor día',
                      value: NumberFormat.currency(
                        symbol: '\$',
                        decimalDigits: 0,
                      ).format(max),
                      color: context.colors.success,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.colors.line,
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Menor valor',
                      value: NumberFormat.currency(
                        symbol: '\$',
                        decimalDigits: 0,
                      ).format(min),
                      color: context.colors.muted,
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

  List<String> _getLabels(PeriodoResumen periodo) {
    final now = DateTime.now();
    return switch (periodo) {
      PeriodoResumen.hoy => List.generate(12, (i) {
          final hora = now.subtract(Duration(hours: 11 - i));
          return '${hora.hour}h';
        }),
      PeriodoResumen.semana => List.generate(7, (i) {
          final dia = now.subtract(Duration(days: 6 - i));
          return _diaAbreviado(dia.weekday);
        }),
      PeriodoResumen.mes => List.generate(30, (i) {
          final dia = now.subtract(Duration(days: 29 - i));
          return '${dia.day}';
        }),
    };
  }

  String _getPeriodLabel(PeriodoResumen periodo) {
    return switch (periodo) {
      PeriodoResumen.hoy => 'Últimas 12 horas',
      PeriodoResumen.semana => 'Últimos 7 días',
      PeriodoResumen.mes => 'Últimos 30 días',
    };
  }

  String _diaAbreviado(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Lun',
      DateTime.tuesday => 'Mar',
      DateTime.wednesday => 'Mié',
      DateTime.thursday => 'Jue',
      DateTime.friday => 'Vie',
      DateTime.saturday => 'Sáb',
      DateTime.sunday => 'Dom',
      _ => '',
    };
  }
}

/// Mini estadística — compacta y discreta.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: context.colors.muted,
              ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
        ),
      ],
    );
  }
}

/// Mini gráfica de tendencia con labels adaptados al período.
class _SparklineConLabels extends StatelessWidget {
  const _SparklineConLabels({
    required this.datos,
    required this.labels,
    required this.color,
    required this.backgroundColor,
  });

  final List<double> datos;
  final List<String> labels;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    // Para series largas, mostrar solo etiquetas cada N elementos
    final displayLabels = _thinLabels(labels);

    return Column(
      children: [
        Expanded(
          child: Semantics(
            label: 'Gráfica de tendencia',
            child: CustomPaint(
              painter: _SparklinePainter(
                datos: datos,
                color: color,
                backgroundColor: backgroundColor,
                textColor: context.colors.muted,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayLabels.map((entry) {
            final isLast = entry.key == labels.length - 1;
            return Expanded(
              child: Text(
                entry.value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      fontWeight:
                          isLast ? FontWeight.w600 : FontWeight.w500,
                      color: isLast
                          ? context.colors.primary
                          : context.colors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Reduce etiquetas para series largas (máx 7 visibles).
  List<MapEntry<int, String>> _thinLabels(List<String> all) {
    if (all.length <= 7) {
      return all.asMap().entries.toList();
    }
    final step = (all.length / 6).ceil();
    final result = <MapEntry<int, String>>[];
    for (var i = 0; i < all.length; i += step) {
      result.add(MapEntry(i, all[i]));
    }
    // Siempre incluir la última
    if (result.last.key != all.length - 1) {
      result.add(MapEntry(all.length - 1, all.last));
    }
    return result;
  }
}

/// Painter para sparkline con área gradiente y puntos.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.datos,
    required this.color,
    required this.backgroundColor,
    required this.textColor,
  });

  final List<double> datos;
  final Color color;
  final Color backgroundColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (datos.isEmpty) return;

    final max = datos.reduce((a, b) => a > b ? a : b);
    final min = datos.reduce((a, b) => a < b ? a : b);
    final range = max - min;

    if (range == 0) {
      _drawFlatLine(canvas, size);
      return;
    }

    _drawGridLines(canvas, size);

    final padding = size.height * 0.15;
    final effectiveHeight = size.height - (padding * 2);
    final points = <Offset>[];
    final stepX = size.width / (datos.length - 1);

    for (var i = 0; i < datos.length; i++) {
      final x = i * stepX;
      final normalizado = (datos[i] - min) / range;
      final y = padding + (effectiveHeight - (normalizado * effectiveHeight));
      points.add(Offset(x, y));
    }

    _drawArea(canvas, size, points);
    _drawLine(canvas, points);
    _drawPoints(canvas, points, max);
  }

  void _drawFlatLine(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    if (datos.length > 1) {
      final stepX = size.width / (datos.length - 1);
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var i = 0; i < datos.length; i++) {
        canvas.drawCircle(Offset(i * stepX, y), 3.5, pointPaint);
      }
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = textColor.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawArea(Canvas canvas, Size size, List<Offset> points) {
    final path = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = points[i - 1];
      final midX = previous.dx + (current.dx - previous.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    path
      ..lineTo(points.last.dx, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.25),
        color.withValues(alpha: 0.05),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final areaPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, areaPaint);
  }

  void _drawLine(Canvas canvas, List<Offset> points) {
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = points[i - 1];
      final midX = previous.dx + (current.dx - previous.dx) / 2;
      linePath.cubicTo(
          midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  void _drawPoints(Canvas canvas, List<Offset> points, double max) {
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final maxPointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: AppAlphas.fill)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isMax = datos[i] == max;

      if (isMax && datos.length > 1) {
        canvas.drawCircle(point, 10, glowPaint);
        canvas.drawCircle(point, 7, borderPaint);
        canvas.drawCircle(point, 5, maxPointPaint);
      } else {
        canvas.drawCircle(point, 5, borderPaint);
        canvas.drawCircle(point, 3.5, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return datos != oldDelegate.datos ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

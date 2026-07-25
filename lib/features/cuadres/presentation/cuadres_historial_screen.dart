import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/widgets/estado_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cuadre_provider.dart';

class CuadresHistorialScreen extends ConsumerWidget {
  const CuadresHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final todosCuadres = ref.watch(cuadreControllerProvider);

    final misCuadres = todosCuadres
        .where((c) => c.dependienteId == user?.id)
        .toList()
      ..sort((a, b) => b.fechaTurno.compareTo(a.fechaTurno));

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Mis Cuadres'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: misCuadres.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: misCuadres.length + 1,
                itemBuilder: (context, index) {
                  if (index == misCuadres.length) {
                    return const SizedBox(height: AppSpacing.lg);
                  }
                  final cuadre = misCuadres[index];
                  return _CuadreCard(
                    key: ValueKey(cuadre.id),
                    cuadre: cuadre,
                    onTap: () => _showCuadreDetail(context, cuadre),
                  );
                },
              ),
      ),
    );
  }

  void _showCuadreDetail(BuildContext context, Cuadre cuadre) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CuadreDetailSheet(cuadre: cuadre),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cuadre Card — identidad visual por estado
// ═══════════════════════════════════════════════════════════════════════════

class _CuadreCard extends StatefulWidget {
  const _CuadreCard({
    super.key,
    required this.cuadre,
    required this.onTap,
  });

  final Cuadre cuadre;
  final VoidCallback onTap;

  @override
  State<_CuadreCard> createState() => _CuadreCardState();
}

class _CuadreCardState extends State<_CuadreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeSlide = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: _CardContent(
          cuadre: widget.cuadre,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.cuadre,
    required this.onTap,
  });

  final Cuadre cuadre;
  final VoidCallback onTap;

  Color _accentColor(BuildContext context) => switch (cuadre.estado) {
        CuadreEstado.aprobado => context.colors.success,
        CuadreEstado.rechazado => context.colors.danger,
        CuadreEstado.pendiente => context.colors.warning,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: ext.surface,
        borderRadius: AppRadii.lgBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.lgBorder,
          splashColor: accent.withValues(alpha: 0.06),
          highlightColor: accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadii.lgBorder,
              border: Border(
                left: BorderSide(color: accent, width: 4),
              ),
              color: accent.withValues(alpha: 0.03),
              boxShadow: AppShadows.subtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Fecha + Estado ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(cuadre.fechaTurno),
                            style: textTheme.titleMedium?.copyWith(
                              color: ext.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Cuadre de cierre',
                            style: textTheme.bodyMedium?.copyWith(
                              color: ext.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    EstadoBadge(
                      estado: cuadre.estado,
                      showBorder: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Divisor ──
                Container(height: 1, color: ext.line),
                const SizedBox(height: AppSpacing.lg),

                // ── Métricas ──
                Row(
                  children: [
                    Expanded(
                      child: _MetricaChip(
                        icon: Icons.receipt_long_outlined,
                        valor: '${cuadre.ventas.length}',
                        label: 'ventas',
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MetricaChip(
                        icon: Icons.inventory_2_outlined,
                        valor: '${cuadre.totalSalidas}',
                        label: 'unidades',
                        accent: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Total hero ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.06),
                    borderRadius: AppRadii.mdBorder,
                    border: Border.all(
                      color: accent.withValues(alpha: AppAlphas.border),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Total',
                        style: textTheme.titleMedium?.copyWith(
                          color: ext.ink,
                        ),
                      ),
                      Text(
                        formatCurrency(cuadre.valorTotal),
                        style: textTheme.headlineMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Comentario del jefe ──
                if (cuadre.estado == CuadreEstado.rechazado &&
                    cuadre.comentarioJefe != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RechazoBanner(
                    comentario: cuadre.comentarioJefe!,
                    accent: accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Métrica Chip — icono + valor + label en fondo tintado
// ═══════════════════════════════════════════════════════════════════════════

class _MetricaChip extends StatelessWidget {
  const _MetricaChip({
    required this.icon,
    required this.valor,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String valor;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ext.surfaceSecondary,
        borderRadius: AppRadii.smBorder,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: textTheme.titleMedium?.copyWith(
                  color: ext.ink,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: ext.muted,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Rechazo Banner — comentario del supervisor cuando el cuadre fue rechazado
// ═══════════════════════════════════════════════════════════════════════════

class _RechazoBanner extends StatelessWidget {
  const _RechazoBanner({
    required this.comentario,
    required this.accent,
  });

  final String comentario;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppAlphas.fill),
        borderRadius: AppRadii.mdBorder,
        border: Border.all(
          color: accent.withValues(alpha: AppAlphas.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comentario del supervisor',
                  style: textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  comentario,
                  style: textTheme.bodyMedium?.copyWith(
                    color: ext.ink,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: ext.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fact_check_outlined,
                size: 56,
                color: ext.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Sin cuadres aún',
              style: textTheme.headlineMedium?.copyWith(
                color: ext.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aquí verás el historial de todos tus cuadres\nde caja una vez cierres tu primer turno.',
              style: textTheme.bodyLarge?.copyWith(
                color: ext.muted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cuadre Detail Sheet — bottom sheet expandible con detalle completo
// ═══════════════════════════════════════════════════════════════════════════

class _CuadreDetailSheet extends StatelessWidget {
  const _CuadreDetailSheet({required this.cuadre});

  final Cuadre cuadre;

  Color _accentColor(BuildContext context) => switch (cuadre.estado) {
        CuadreEstado.aprobado => context.colors.success,
        CuadreEstado.rechazado => context.colors.danger,
        CuadreEstado.pendiente => context.colors.warning,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: ext.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ext.line,
                    borderRadius: AppRadii.pillBorder,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle del Cuadre',
                            style: textTheme.headlineMedium?.copyWith(
                              color: ext.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            compactDateFormatter.format(cuadre.fechaTurno),
                            style: textTheme.bodyLarge?.copyWith(
                              color: ext.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    EstadoBadge(
                      estado: cuadre.estado,
                      showBorder: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Content ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  children: [
                    // ── Resumen Card ──
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: ext.surface,
                        borderRadius: AppRadii.lgBorder,
                        boxShadow: AppShadows.subtle,
                        border: Border(
                          left: BorderSide(color: accent, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen',
                            style: textTheme.titleMedium?.copyWith(
                              color: ext.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _DetailRow(
                            label: 'Número de ventas',
                            valor: '${cuadre.ventas.length}',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          _DetailRow(
                            label: 'Unidades vendidas',
                            valor: '${cuadre.totalSalidas}',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          _DetailRow(
                            label: 'Total',
                            valor: formatCurrency(cuadre.valorTotal),
                            isHighlighted: true,
                            accent: accent,
                          ),
                        ],
                      ),
                    ),

                    // ── Comentario del supervisor ──
                    if (cuadre.comentarioJefe != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: AppAlphas.fill),
                          borderRadius: AppRadii.lgBorder,
                          border: Border.all(
                            color: accent.withValues(alpha: AppAlphas.border),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              cuadre.estado == CuadreEstado.rechazado
                                  ? Icons.error_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 20,
                              color: accent,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comentario del supervisor',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    cuadre.comentarioJefe!,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: ext.ink,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Ventas del Cuadre ──
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: ext.surface,
                        borderRadius: AppRadii.lgBorder,
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: ext.surfaceSecondary,
                                  borderRadius: AppRadii.smBorder,
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Ventas del Cuadre',
                                style: textTheme.titleMedium?.copyWith(
                                  color: ext.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ...cuadre.ventas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final venta = entry.value;
                            final isLast = index == cuadre.ventas.length - 1;
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Venta #${venta.id.substring(0, 6).toUpperCase()}',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: ext.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(venta.total),
                                      style: textTheme.titleMedium?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isLast) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Container(height: 1, color: ext.line),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.valor,
    this.isHighlighted = false,
    this.accent,
  });

  final String label;
  final String valor;
  final bool isHighlighted;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: isHighlighted ? 16 : 15,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: ext.muted,
          ),
        ),
        Text(
          valor,
          style: textTheme.titleMedium?.copyWith(
            fontSize: isHighlighted ? 20 : 17,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            color: isHighlighted && accent != null ? accent : ext.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

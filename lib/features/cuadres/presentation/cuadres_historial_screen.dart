import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cuadre_provider.dart';

/// Pantalla de historial de cuadres del dependiente
/// 
/// Diseñada con principios UI/UX Pro Max:
/// - Jerarquía visual clara con cards individuales
/// - Estados badge con contraste óptimo
/// - Tabular figures para precios
/// - Touch targets ≥44pt
/// - Spacing scale sistemático (8, 12, 16, 24)
/// - Empty state informativo
class CuadresHistorialScreen extends ConsumerWidget {
  const CuadresHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final todosCuadres = ref.watch(cuadreControllerProvider);
    
    // Filtrar solo los cuadres del dependiente actual
    final misCuadres = todosCuadres
        .where((c) => c.dependienteId == user?.id)
        .toList()
      ..sort((a, b) => b.fechaTurno.compareTo(a.fechaTurno));

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          'Mis Cuadres',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: context.colors.ink,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.ink),
          iconSize: 24,
          padding: const EdgeInsets.all(12),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: misCuadres.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: misCuadres.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cuadre = misCuadres[index];
                  return _CuadreCard(
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
// Cuadre Card (UI/UX Pro Max)
// ═══════════════════════════════════════════════════════════════════════════

class _CuadreCard extends StatelessWidget {
  const _CuadreCard({
    required this.cuadre,
    required this.onTap,
  });

  final Cuadre cuadre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colors.ink.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Fecha y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compactDateFormatter.format(cuadre.fechaTurno),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.colors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Turno del día',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.colors.muted,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _EstadoBadge(estado: cuadre.estado),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Divider
              Container(
                height: 1,
                color: context.colors.background,
              ),
              
              const SizedBox(height: 16),
              
              // Métricas del cuadre
              Row(
                children: [
                  Expanded(
                    child: _MetricaItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Ventas',
                      valor: '${cuadre.ventas.length}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.colors.background,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricaItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Unidades',
                      valor: '${cuadre.totalSalidas}',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Total destacado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      formatCurrency(cuadre.valorTotal),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                        letterSpacing: -0.6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comentario del jefe si existe y fue rechazado
              if (cuadre.estado == CuadreEstado.rechazado && 
                  cuadre.comentarioJefe != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colors.danger.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: context.colors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cuadre.comentarioJefe!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colors.danger,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Estado Badge
// ═══════════════════════════════════════════════════════════════════════════

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final CuadreEstado estado;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (estado) {
      CuadreEstado.aprobado => (context.colors.success, Icons.check_circle_rounded),
      CuadreEstado.rechazado => (context.colors.danger, Icons.cancel_rounded),
      CuadreEstado.pendiente => (context.colors.warning, Icons.schedule_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            estado.label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Métrica Item
// ═══════════════════════════════════════════════════════════════════════════

class _MetricaItem extends StatelessWidget {
  const _MetricaItem({
    required this.icon,
    required this.label,
    required this.valor,
  });

  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: context.colors.muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                  letterSpacing: -0.4,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: context.colors.muted,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fact_check_outlined,
                size: 64,
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin cuadres aún',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
                letterSpacing: -0.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí verás el historial de todos tus cuadres de caja una vez cierres tu primer turno.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.colors.muted,
                letterSpacing: -0.3,
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
// Cuadre Detail Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _CuadreDetailSheet extends StatelessWidget {
  const _CuadreDetailSheet({required this.cuadre});

  final Cuadre cuadre;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle del Cuadre',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: context.colors.ink,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            compactDateFormatter.format(cuadre.fechaTurno),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: context.colors.muted,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _EstadoBadge(estado: cuadre.estado),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Resumen Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.ink.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Número de ventas',
                            valor: '${cuadre.ventas.length}',
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Unidades vendidas',
                            valor: '${cuadre.totalSalidas}',
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Total',
                            valor: formatCurrency(cuadre.valorTotal),
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                    
                    // Comentario si existe
                    if (cuadre.comentarioJefe != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cuadre.estado == CuadreEstado.rechazado
                              ? context.colors.danger.withValues(alpha: 0.08)
                              : context.colors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cuadre.estado == CuadreEstado.rechazado
                                ? context.colors.danger.withValues(alpha: 0.2)
                                : context.colors.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  cuadre.estado == CuadreEstado.rechazado
                                      ? Icons.error_outline_rounded
                                      : Icons.info_outline_rounded,
                                  size: 20,
                                  color: cuadre.estado == CuadreEstado.rechazado
                                      ? context.colors.danger
                                      : context.colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Comentario del supervisor',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cuadre.estado == CuadreEstado.rechazado
                                        ? context.colors.danger
                                        : context.colors.primary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cuadre.comentarioJefe!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: context.colors.ink,
                                letterSpacing: -0.2,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Lista de ventas
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.ink.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: context.colors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                  color: context.colors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Ventas del Cuadre',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.ink,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...cuadre.ventas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final venta = entry.value;
                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Venta #${venta.id.substring(0, 6).toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.ink,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(venta.total),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.primary,
                                        letterSpacing: -0.3,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                                if (index < cuadre.ventas.length - 1) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 1,
                                    color: context.colors.background,
                                  ),
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
  });

  final String label;
  final String valor;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 15,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: context.colors.muted,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: isHighlighted ? 20 : 17,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            color: isHighlighted ? context.colors.primary : context.colors.ink,
            letterSpacing: isHighlighted ? -0.5 : -0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

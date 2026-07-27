import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/pago.dart';
import '../../../shared/models/venta.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../providers/turno_provider.dart';
import '../../ventas/providers/venta_provider.dart';

class CuadreResumenScreen extends ConsumerStatefulWidget {
  const CuadreResumenScreen({super.key});

  @override
  ConsumerState<CuadreResumenScreen> createState() =>
      _CuadreResumenScreenState();
}

class _CuadreResumenScreenState extends ConsumerState<CuadreResumenScreen> {
  bool _mostrarProductos = false;
  bool _isLoading = false;

  Map<String, _ProductoAgrupado> _agruparProductos(List<Venta> ventas) {
    final map = <String, _ProductoAgrupado>{};
    for (final venta in ventas) {
      for (final item in venta.items) {
        final existing = map[item.productoId];
        if (existing != null) {
          map[item.productoId] = _ProductoAgrupado(
            nombre: item.productoNombre,
            cantidad: existing.cantidad + item.cantidad,
            subtotal: existing.subtotal + item.subtotal,
          );
        } else {
          map[item.productoId] = _ProductoAgrupado(
            nombre: item.productoNombre,
            cantidad: item.cantidad,
            subtotal: item.subtotal,
          );
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final turno = ref.watch(turnoControllerProvider);
    final ventas = ref.watch(ventasDelTurnoProvider);

    final total = ventas.fold(0.0, (sum, v) => sum + v.total);
    final totalUnidades = ventas.fold(0, (sum, v) => sum + v.totalUnidades);

    // ── Totales por método de pago ──
    double totalEfectivo = 0;
    double totalTransferencia = 0;
    for (final venta in ventas) {
      for (final pago in venta.pagos) {
        if (pago.metodo == MetodoPago.efectivo) {
          totalEfectivo += pago.monto;
        } else if (pago.metodo == MetodoPago.transferencia) {
          totalTransferencia += pago.monto;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del turno'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── Hero KPIs ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _HeroKPIs(
                    total: total,
                    ventasCount: ventas.length,
                    unidades: totalUnidades,
                    totalEfectivo: totalEfectivo,
                    totalTransferencia: totalTransferencia,
                  ),
                ),

                // ── Header info ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _ResumenHeader(turno: turno),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Toggle ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleOption(
                          label: 'Resumen',
                          icon: Icons.receipt_long_rounded,
                          selected: !_mostrarProductos,
                          onTap: () =>
                              setState(() => _mostrarProductos = false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ToggleOption(
                          label: 'Productos',
                          icon: Icons.inventory_2_rounded,
                          selected: _mostrarProductos,
                          onTap: () =>
                              setState(() => _mostrarProductos = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Contenido scrolleable ──
                Expanded(
                  child: ventas.isEmpty
                      ? const _EmptyResumen()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          children: _mostrarProductos
                              ? _buildProductosView(
                                  context, ventas, total, totalUnidades)
                              : _buildResumenView(
                                  context,
                                  ventas,
                                  total,
                                  totalUnidades,
                                  totalEfectivo,
                                  totalTransferencia,
                                ),
                        ),
                ),

                // ── Botón confirmar ──
                _ConfirmBar(
                  enabled: ventas.isNotEmpty && !_isLoading,
                  isLoading: _isLoading,
                  total: total,
                  onConfirm: () => _confirmarEnvio(context, ref, ventas),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResumenView(
    BuildContext context,
    List<Venta> ventas,
    double total,
    int totalUnidades,
    double totalEfectivo,
    double totalTransferencia,
  ) {
    return [
      for (final venta in ventas) ...[
        _ResumenVentaCard(venta: venta),
        const SizedBox(height: AppSpacing.sm),
      ],
      const SizedBox(height: AppSpacing.xs),
      const _SlimDivider(),
      const SizedBox(height: AppSpacing.md),
      _buildTotal(
        context,
        '${ventas.length} ${ventas.length == 1 ? 'venta' : 'ventas'}',
        totalUnidades,
        total,
      ),
    ];
  }

  List<Widget> _buildProductosView(
    BuildContext context,
    List<Venta> ventas,
    double total,
    int totalUnidades,
  ) {
    final productos = _agruparProductos(ventas);
    final sorted = productos.values.toList()
      ..sort((a, b) => b.subtotal.compareTo(a.subtotal));

    return [
      ...sorted.map(
        (p) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _ProductoCard(producto: p),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      const _SlimDivider(),
      const SizedBox(height: AppSpacing.md),
      _buildTotal(
        context,
        '${productos.length} ${productos.length == 1 ? 'producto' : 'productos'}',
        totalUnidades,
        total,
      ),
    ];
  }

  Widget _buildTotal(
    BuildContext context,
    String label,
    int unidades,
    double total,
  ) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label · $unidades ${unidades == 1 ? 'ud.' : 'uds.'}',
              style: tt.bodySmall?.copyWith(color: ext.muted),
            ),
            const SizedBox(height: 2),
            Text(
              'Total de ventas',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Text(
          formatCurrency(total),
          style: tt.headlineMedium?.copyWith(
            color: ext.primary,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarEnvio(
    BuildContext context,
    WidgetRef ref,
    List<Venta> ventas,
  ) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null || ventas.isEmpty) return;

    final total = ventas.fold(0.0, (sum, v) => sum + v.total);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('\u00bfEnviar cuadre?'),
        content: Text(
          'Se enviar\u00e1 un cuadre por ${formatCurrency(total)} '
          'para que el jefe lo revise.\n\u00bfDeseas enviarlo ahora?',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isLoading = true);

    final error = ref
        .read(cuadreControllerProvider.notifier)
        .crearCuadrePendiente(dependiente: user, ventas: ventas);

    if (error != null) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: context.colors.danger),
      );
      return;
    }

    // NO limpiar las ventas aquí porque el dependiente puede seguir editando el cuadre
    // Las ventas solo se limpian cuando el admin aprueba/rechaza o al iniciar nuevo turno
    ref.read(turnoControllerProvider.notifier).enviarCuadre();
    if (context.mounted) context.go('/dependiente/turno');
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ProductoAgrupado {
  final String nombre;
  final int cantidad;
  final double subtotal;

  const _ProductoAgrupado({
    required this.nombre,
    required this.cantidad,
    required this.subtotal,
  });
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _HeroKPIs extends StatelessWidget {
  const _HeroKPIs({
    required this.total,
    required this.ventasCount,
    required this.unidades,
    required this.totalEfectivo,
    required this.totalTransferencia,
  });

  final double total;
  final int ventasCount;
  final int unidades;
  final double totalEfectivo;
  final double totalTransferencia;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: ext.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        children: [
          // ── Total hero ──
          Text(
            formatCurrency(total),
            style: tt.displayMedium?.copyWith(
              color: ext.primary,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Total de ventas del turno',
            style: tt.bodyMedium?.copyWith(color: ext.muted),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Chips de método de pago ──
          if (totalEfectivo > 0 || totalTransferencia > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  if (totalEfectivo > 0)
                    Expanded(
                      child: _PagoChip(
                        icon: Icons.payments_outlined,
                        label: 'Efectivo',
                        amount: totalEfectivo,
                        color: ext.success,
                      ),
                    ),
                  if (totalEfectivo > 0 && totalTransferencia > 0)
                    const SizedBox(width: AppSpacing.sm),
                  if (totalTransferencia > 0)
                    Expanded(
                      child: _PagoChip(
                        icon: Icons.account_balance_outlined,
                        label: 'Transferencia',
                        amount: totalTransferencia,
                        color: ext.warning,
                      ),
                    ),
                ],
              ),
            ),

          if (totalEfectivo > 0 || totalTransferencia > 0)
            const SizedBox(height: AppSpacing.sm + 2),

          // ── Métricas secundarias ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.receipt_long_rounded,
                    value: '$ventasCount',
                    label: ventasCount == 1 ? 'venta' : 'ventas',
                    color: ext.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.inventory_2_rounded,
                    value: '$unidades',
                    label: unidades == 1 ? 'ud.' : 'uds.',
                    color: ext.success,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: ext.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppAlphas.fill),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ext.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: tt.bodySmall?.copyWith(color: ext.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenHeader extends StatelessWidget {
  const _ResumenHeader({required this.turno});

  final TurnoState turno;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          compactDateFormatter.format(DateTime.now()),
          style: tt.titleLarge,
        ),
        if (turno.horaInicio != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              color: ext.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: ext.muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Desde ${timeFormatter.format(turno.horaInicio!)}',
                  style: tt.bodySmall?.copyWith(
                    color: ext.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected
              ? ext.primary.withValues(alpha: AppAlphas.fillStrong)
              : ext.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected
                ? ext.primary.withValues(alpha: 0.3)
                : ext.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? ext.primary : ext.muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: selected ? ext.primary : ext.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenVentaCard extends StatelessWidget {
  const _ResumenVentaCard({required this.venta});

  final Venta venta;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    // Detectar método de pago
    final MetodoPago metodoPago;
    if (venta.pagos.length > 1) {
      metodoPago = MetodoPago.mixto;
    } else if (venta.pagos.isNotEmpty) {
      metodoPago = venta.pagos.first.metodo;
    } else {
      metodoPago = MetodoPago.efectivo;
    }

    final chipColor = metodoPago == MetodoPago.efectivo
        ? ext.success
        : metodoPago == MetodoPago.transferencia
            ? ext.warning
            : ext.info;

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          title: Text(
            'Venta a las ${timeFormatter.format(venta.fecha)}',
            style: tt.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                // Chip de artículos
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ext.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    '${venta.items.length} ${venta.items.length == 1 ? 'artículo' : 'artículos'}',
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ext.ink,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Chip de método de pago
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(metodoPago.icon, size: 12, color: chipColor),
                      const SizedBox(width: 4),
                      Text(
                        metodoPago.label,
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          trailing: Text(
            formatCurrency(venta.total),
            style: tt.titleMedium?.copyWith(
              color: ext.primary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          children: [
            const _SlimDivider(),
            const SizedBox(height: AppSpacing.sm),
            for (final item in venta.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Text(
                      '${item.cantidad}x',
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ext.muted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.productoNombre,
                        style: tt.bodyMedium?.copyWith(color: ext.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatCurrency(item.subtotal),
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ext.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({required this.producto});

  final _ProductoAgrupado producto;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ext.primary.withValues(alpha: AppAlphas.fill),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: ext.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ext.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${producto.cantidad} ${producto.cantidad == 1 ? 'ud.' : 'uds.'} vendidas',
                    style: tt.bodySmall?.copyWith(color: ext.muted),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(producto.subtotal),
              style: tt.titleMedium?.copyWith(
                color: ext.primary,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResumen extends StatelessWidget {
  const _EmptyResumen();

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ext.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: ext.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sin ventas aún',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Las ventas realizadas en este turno\naparecerán aquí.',
              style: tt.bodyMedium?.copyWith(color: ext.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.enabled,
    required this.isLoading,
    required this.total,
    required this.onConfirm,
  });

  final bool enabled;
  final bool isLoading;
  final double total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final ext = context.colors;
    final tt = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ext.surface,
        border: Border(
          top: BorderSide(color: ext.line.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se enviará ',
                        style: tt.bodyMedium?.copyWith(color: ext.muted),
                      ),
                      Text(
                        formatCurrency(total),
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ext.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: enabled
                      ? () {
                          Haptics.confirm(context);
                          onConfirm();
                        }
                      : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(isLoading ? 'Enviando...' : 'Confirmar y enviar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slim divider helper ─────────────────────────────────────────────────────

class _SlimDivider extends StatelessWidget {
  const _SlimDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: context.colors.line.withValues(alpha: 0.6),
    );
  }
}

class _PagoChip extends StatelessWidget {
  const _PagoChip({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            formatCurrency(amount),
            style: tt.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

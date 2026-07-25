import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _HeroKPIs(
                    total: total,
                    ventasCount: ventas.length,
                    unidades: totalUnidades,
                  ),
                ),

                // ── Header info ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _ResumenHeader(turno: turno),
                ),
                const SizedBox(height: 16),

                // ── Toggle ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      const SizedBox(width: 8),
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
                const SizedBox(height: 16),

                // ── Contenido scrolleable ──
                Expanded(
                  child: ventas.isEmpty
                      ? const _EmptyResumen()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          children: _mostrarProductos
                              ? _buildProductosView(
                                  context, ventas, total, totalUnidades)
                              : _buildResumenView(
                                  context, ventas, total, totalUnidades),
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
  ) {
    return [
      for (final venta in ventas) ...[
        _ResumenVentaCard(venta: venta),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      const Divider(),
      const SizedBox(height: 12),
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
          padding: const EdgeInsets.only(bottom: 10),
          child: _ProductoCard(producto: p),
        ),
      ),
      const SizedBox(height: 6),
      const Divider(),
      const SizedBox(height: 12),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label \u00b7 $unidades ${unidades == 1 ? 'unidad' : 'unidades'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              'Total de ventas',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          formatCurrency(total),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.colors.primary,
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
  });

  final double total;
  final int ventasCount;
  final int unidades;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Total hero
        Text(
          formatCurrency(total),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Total de ventas del turno',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        // Métricas secundarias
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_rounded,
                value: '$ventasCount',
                label: ventasCount == 1 ? 'venta' : 'ventas',
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.inventory_2_rounded,
                value: '$unidades',
                label: unidades == 1 ? 'unidad' : 'unidades',
                color: context.colors.success,
              ),
            ),
          ],
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.colors.line.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppAlphas.fill),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
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
    return Row(
      children: [
        Text(
          compactDateFormatter.format(DateTime.now()),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (turno.horaInicio != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: context.colors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Desde ${timeFormatter.format(turno.horaInicio!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w500,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary.withValues(alpha: AppAlphas.fill)
              : context.colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? context.colors.primary : context.colors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selected ? context.colors.primary : context.colors.ink,
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
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Venta a las ${timeFormatter.format(venta.fecha)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '${venta.items.length} ${venta.items.length == 1 ? 'art\u00edculo' : 'art\u00edculos'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          trailing: Text(
            formatCurrency(venta.total),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            for (final item in venta.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.productoNombre}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      formatCurrency(item.subtotal),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: AppAlphas.fill),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: context.colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${producto.cantidad} ${producto.cantidad == 1 ? 'unidad' : 'unidades'} vendidas',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(producto.subtotal),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin ventas a\u00fan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Las ventas realizadas en este turno\naparecer\u00e1n aqu\u00ed.',
              style: Theme.of(context).textTheme.bodyMedium,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.line.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se enviar\u00e1 ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        formatCurrency(total),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.colors.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 54,
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
                      : const Icon(Icons.send_rounded),
                  label: Text(isLoading ? 'Enviando...' : 'Confirmar y enviar'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

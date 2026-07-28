import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/pago.dart';
import '../../../shared/models/venta.dart';
import '../../../shared/widgets/estado_badge.dart';
import '../providers/cuadre_provider.dart';

class CuadreDetalleScreen extends ConsumerStatefulWidget {
  const CuadreDetalleScreen({super.key, required this.cuadreId});

  final String cuadreId;

  @override
  ConsumerState<CuadreDetalleScreen> createState() =>
      _CuadreDetalleScreenState();
}

class _CuadreDetalleScreenState extends ConsumerState<CuadreDetalleScreen>
    with SingleTickerProviderStateMixin {
  bool _mostrarProductos = false;
  bool _isApproving = false;
  bool _isRejecting = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

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

  _ResumenPagos _calcularResumenPagos(List<Venta> ventas) {
    double efectivoTotal = 0.0;
    double transferenciaTotal = 0.0;
    int cantidadEfectivo = 0;
    int cantidadTransferencia = 0;
    int cantidadMixto = 0;

    for (final venta in ventas) {
      if (venta.pagos.isEmpty) continue;

      // Si hay más de un pago, es mixto
      if (venta.pagos.length > 1) {
        cantidadMixto++;
        // Sumar los montos de cada tipo de pago
        for (final pago in venta.pagos) {
          if (pago.metodo == MetodoPago.efectivo) {
            efectivoTotal += pago.monto;
          } else if (pago.metodo == MetodoPago.transferencia) {
            transferenciaTotal += pago.monto;
          }
        }
      } else {
        // Pago único
        final pago = venta.pagos.first;
        if (pago.metodo == MetodoPago.efectivo) {
          cantidadEfectivo++;
          efectivoTotal += pago.monto;
        } else if (pago.metodo == MetodoPago.transferencia) {
          cantidadTransferencia++;
          transferenciaTotal += pago.monto;
        }
      }
    }

    return _ResumenPagos(
      efectivoTotal: efectivoTotal,
      transferenciaTotal: transferenciaTotal,
      cantidadEfectivo: cantidadEfectivo,
      cantidadTransferencia: cantidadTransferencia,
      cantidadMixto: cantidadMixto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuadres = ref.watch(cuadreControllerProvider);
    final cuadre = cuadres.where((c) => c.id == widget.cuadreId).firstOrNull;

    if (cuadre == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del cuadre')),
        body: const Center(child: Text('Cuadre no encontrado')),
      );
    }

    final isPendiente = cuadre.estado == CuadreEstado.pendiente;
    final ventas = cuadre.ventas;
    final total = cuadre.valorTotal;
    final totalUnidades = cuadre.totalSalidas;
    final comentario = cuadre.comentarioJefe;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del cuadre'),
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
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: _slideAnimation.value * 8,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // ── Header con avatar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _DetalleHeader(cuadre: cuadre),
                  ),

                  // ── Hero KPIs ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _AnimatedHeroKPIs(
                      total: total,
                      ventasCount: ventas.length,
                      unidades: totalUnidades,
                      estado: cuadre.estado,
                    ),
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
                        ? const _EmptyDetalle()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.015),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Builder(
                              builder: (ctx) {
                                final items = _mostrarProductos
                                    ? _buildProductosView(
                                        ctx, ventas, total, totalUnidades,
                                        comentario)
                                    : _buildResumenView(
                                        ctx, ventas, total, totalUnidades,
                                        comentario);
                                return ListView.builder(
                                  key: _mostrarProductos
                                      ? const ValueKey('productos')
                                      : const ValueKey('resumen'),
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 16),
                                  itemCount: items.length,
                                  itemBuilder: (_, i) => items[i],
                                );
                              },
                            ),
                          ),
                  ),

                  // ── Acciones ──
                  if (isPendiente)
                    _AccionesBar(
                      cuadreId: cuadre.id,
                      isApproving: _isApproving,
                      isRejecting: _isRejecting,
                      onApproving: (v) => setState(() => _isApproving = v),
                      onRejecting: (v) => setState(() => _isRejecting = v),
                    ),
                ],
              ),
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
    String? comentario,
  ) {
    final resumenPagos = _calcularResumenPagos(ventas);
    
    final children = <Widget>[
      for (int i = 0; i < ventas.length; i++)
        _StaggeredItem(
          index: i,
          child: _VentaViewCard(venta: ventas[i]),
        ),
      if (ventas.isNotEmpty) const SizedBox(height: 10),
      const SizedBox(height: 6),
      const Divider(),
      const SizedBox(height: 12),
      
      // Resumen de pagos
      _ResumenPagosCard(resumen: resumenPagos, total: total),
      const SizedBox(height: 16),
      
      _buildTotal(
        context,
        '${ventas.length} ${ventas.length == 1 ? 'venta' : 'ventas'}',
        totalUnidades,
        total,
      ),
    ];
    if (comentario != null) {
      children.addAll([
        const SizedBox(height: 16),
        _ComentarioJefe(comentario: comentario),
      ]);
    }
    children.add(const SizedBox(height: 16));
    return children;
  }

  List<Widget> _buildProductosView(
    BuildContext context,
    List<Venta> ventas,
    double total,
    int totalUnidades,
    String? comentario,
  ) {
    final productos = _agruparProductos(ventas);
    final sorted = productos.values.toList()
      ..sort((a, b) => b.subtotal.compareTo(a.subtotal));

    final children = <Widget>[
      for (int i = 0; i < sorted.length; i++)
        _StaggeredItem(
          index: i,
          child: _ProductoCard(producto: sorted[i]),
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
    if (comentario != null) {
      children.addAll([
        const SizedBox(height: 16),
        _ComentarioJefe(comentario: comentario),
      ]);
    }
    children.add(const SizedBox(height: 16));
    return children;
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

class _ResumenPagos {
  final double efectivoTotal;
  final double transferenciaTotal;
  final int cantidadEfectivo;
  final int cantidadTransferencia;
  final int cantidadMixto;

  const _ResumenPagos({
    required this.efectivoTotal,
    required this.transferenciaTotal,
    required this.cantidadEfectivo,
    required this.cantidadTransferencia,
    required this.cantidadMixto,
  });
}

// ─── Staggered list item ─────────────────────────────────────────────────────

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _startDelayed();
  }

  Future<void> _startDelayed() async {
    await Future.delayed(Duration(milliseconds: (widget.index * 60).clamp(0, 400)));
    if (mounted) _controller.forward();
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
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 12,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: widget.child,
      ),
    );
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _DetalleHeader extends StatelessWidget {
  const _DetalleHeader({required this.cuadre});

  final Cuadre cuadre;

  @override
  Widget build(BuildContext context) {
    final initials = cuadre.dependienteNombre
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: context.colors.primary.withValues(alpha: AppAlphas.fillStrong),
          child: Text(
            initials,
            style: TextStyle(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cuadre.dependienteNombre,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                compactDateFormatter.format(cuadre.fechaTurno),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        EstadoBadge(estado: cuadre.estado),
      ],
    );
  }
}

class _AnimatedHeroKPIs extends StatefulWidget {
  const _AnimatedHeroKPIs({
    required this.total,
    required this.ventasCount,
    required this.unidades,
    required this.estado,
  });

  final double total;
  final int ventasCount;
  final int unidades;
  final CuadreEstado estado;

  @override
  State<_AnimatedHeroKPIs> createState() => _AnimatedHeroKPIsState();
}

class _AnimatedHeroKPIsState extends State<_AnimatedHeroKPIs>
    with TickerProviderStateMixin {
  late final AnimationController _countController;
  late final Animation<double> _countAnimation;
  late final AnimationController _metricsController;
  late final Animation<double> _metricsScale;
  late final Animation<double> _metricsFade;

  @override
  void initState() {
    super.initState();

    // Count animation for total value
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );

    // Scale-in for metric cards
    _metricsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _metricsScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _metricsController, curve: Curves.easeOutBack),
    );
    _metricsFade = CurvedAnimation(
      parent: _metricsController,
      curve: Curves.easeOutCubic,
    );

    // Start sequentially: count first, then metrics
    _countController.forward().then((_) {
      if (mounted) _metricsController.forward();
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    _metricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Total hero — animated count
        AnimatedBuilder(
          animation: _countAnimation,
          builder: (context, child) {
            final currentValue = widget.total * _countAnimation.value;
            return Text(
              formatCurrency(currentValue),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          'Total del cuadre',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        // Metric cards — scale in with stagger
        AnimatedBuilder(
          animation: _metricsController,
          builder: (context, child) {
            return Opacity(
              opacity: _metricsFade.value,
              child: Transform.scale(
                scale: _metricsScale.value,
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.receipt_long_rounded,
                  value: '${widget.ventasCount}',
                  label: widget.ventasCount == 1 ? 'venta' : 'ventas',
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.inventory_2_rounded,
                  value: '${widget.unidades}',
                  label: widget.unidades == 1 ? 'unidad' : 'unidades',
                  color: context.colors.success,
                ),
              ),
            ],
          ),
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
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? context.colors.primary : context.colors.muted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: selected ? context.colors.primary : context.colors.ink,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VentaViewCard extends StatelessWidget {
  const _VentaViewCard({required this.venta});

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/admin/cuadres/ventas/${venta.id}', extra: venta),
        borderRadius: BorderRadius.circular(12),
        child: Card(
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
                  const SizedBox(width: 6),
                  // Badge de método de pago
                  if (metodoPago != null)
                    Builder(
                      builder: (context) {
                        final chipColor = metodoPago == MetodoPago.efectivo
                            ? context.colors.success
                            : metodoPago == MetodoPago.transferencia
                                ? context.colors.warning
                                : context.colors.info;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                metodoPago!.icon,
                                size: 12,
                                color: chipColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                metodoPago.label,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: chipColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

class _ResumenPagosCard extends StatelessWidget {
  const _ResumenPagosCard({
    required this.resumen,
    required this.total,
  });

  final _ResumenPagos resumen;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: context.colors.line.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de pagos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Totales por método de pago
          if (resumen.efectivoTotal > 0) ...[
            _ResumenPagoRow(
              icon: Icons.payments_rounded,
              label: 'Efectivo',
              monto: resumen.efectivoTotal,
              color: context.colors.success,
            ),
            const SizedBox(height: 10),
          ],
          
          if (resumen.transferenciaTotal > 0) ...[
            _ResumenPagoRow(
              icon: Icons.credit_card_rounded,
              label: 'Transferencia',
              monto: resumen.transferenciaTotal,
              color: context.colors.warning,
            ),
            const SizedBox(height: 10),
          ],
          
          // Divider antes del total
          if (resumen.efectivoTotal > 0 || resumen.transferenciaTotal > 0) ...[
            const Divider(height: 20),
          ],
          
          // Total general
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatCurrency(total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          
          // Cantidad de pagos por tipo
          Text(
            'Cantidad de pagos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
            ),
          ),
          const SizedBox(height: 10),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (resumen.cantidadEfectivo > 0)
                _CantidadPagoBadge(
                  icon: Icons.payments_rounded,
                  label: 'Efectivo',
                  cantidad: resumen.cantidadEfectivo,
                  color: context.colors.success,
                ),
              if (resumen.cantidadTransferencia > 0)
                _CantidadPagoBadge(
                  icon: Icons.credit_card_rounded,
                  label: 'Transferencia',
                  cantidad: resumen.cantidadTransferencia,
                  color: context.colors.warning,
                ),
              if (resumen.cantidadMixto > 0)
                _CantidadPagoBadge(
                  icon: Icons.sync_alt_rounded,
                  label: 'Mixto',
                  cantidad: resumen.cantidadMixto,
                  color: context.colors.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenPagoRow extends StatelessWidget {
  const _ResumenPagoRow({
    required this.icon,
    required this.label,
    required this.monto,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double monto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          formatCurrency(monto),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CantidadPagoBadge extends StatelessWidget {
  const _CantidadPagoBadge({
    required this.icon,
    required this.label,
    required this.cantidad,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int cantidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$cantidad',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComentarioJefe extends StatelessWidget {
  const _ComentarioJefe({required this.comentario});

  final String comentario;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: context.colors.danger.withValues(alpha: AppAlphas.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: context.colors.danger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comentario del jefe',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(comentario, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetalle extends StatelessWidget {
  const _EmptyDetalle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Icono de recibo vacío',
              child: Container(
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
            ),
            const SizedBox(height: 20),
            Text(
              'Sin ventas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Este cuadre no tiene ventas registradas.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Volver a cuadres'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionesBar extends ConsumerWidget {
  const _AccionesBar({
    required this.cuadreId,
    required this.isApproving,
    required this.isRejecting,
    required this.onApproving,
    required this.onRejecting,
  });

  final String cuadreId;
  final bool isApproving;
  final bool isRejecting;
  final ValueChanged<bool> onApproving;
  final ValueChanged<bool> onRejecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Row(
            children: [
              // Rechazar — secondary
              TextButton.icon(
                onPressed: (isApproving || isRejecting)
                    ? null
                    : () => _confirmarRechazo(context, ref),
                icon: isRejecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.danger,
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 20),
                label: const Text('Rechazar'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.danger,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Confirmar — primary, prominent
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isApproving || isRejecting)
                      ? null
                      : () => _confirmarAprobacion(context, ref),
                  icon: isApproving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
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

  Future<void> _confirmarAprobacion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('\u00bfConfirmar cuadre?'),
        content: const Text(
          'Se marcar\u00e1 este cuadre como aprobado. '
          'El stock ya fue descontado al registrar las ventas.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      onApproving(true);
      Haptics.confirm(context);
      ref.read(cuadreControllerProvider.notifier).confirmarCuadre(cuadreId);
      context.go('/admin/cuadres');
    }
  }

  Future<void> _confirmarRechazo(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();

    final comment = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            title: const Text('Rechazar cuadre'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '\u00bfEst\u00e1s seguro? Las ventas de este cuadre '
                  'ser\u00e1n canceladas y el stock revertido.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Motivo del rechazo (obligatorio)',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDlg(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final v = ctrl.text.trim();
                  if (v.isEmpty) {
                    setDlg(() => errorText = 'El motivo es obligatorio');
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.danger,
                ),
                child: const Text('Rechazar'),
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();

    if (comment != null && comment.isNotEmpty && context.mounted) {
      onRejecting(true);
      Haptics.warning(context);
      ref
          .read(cuadreControllerProvider.notifier)
          .rechazarCuadre(cuadreId, comment);
      context.go('/admin/cuadres');
    }
  }
}

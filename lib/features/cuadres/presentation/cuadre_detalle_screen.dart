import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/venta.dart';
import '../providers/cuadre_provider.dart';

class CuadreDetalleScreen extends ConsumerStatefulWidget {
  const CuadreDetalleScreen({super.key, required this.cuadreId});

  final String cuadreId;

  @override
  ConsumerState<CuadreDetalleScreen> createState() =>
      _CuadreDetalleScreenState();
}

class _CuadreDetalleScreenState extends ConsumerState<CuadreDetalleScreen> {
  bool _mostrarProductos = false;

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
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _DetalleHeader(cuadre: cuadre),
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
                      onTap: () => setState(() => _mostrarProductos = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleOption(
                      label: 'Productos',
                      icon: Icons.inventory_2_rounded,
                      selected: _mostrarProductos,
                      onTap: () => setState(() => _mostrarProductos = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Contenido scrolleable ──
            Expanded(
              child: ventas.isEmpty
                  ? Card(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Sin ventas en este cuadre.'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      children: _mostrarProductos
                          ? _buildProductosView(
                              context, ventas, total, totalUnidades, comentario)
                          : _buildResumenView(
                              context, ventas, total, totalUnidades, comentario),
                    ),
            ),

            // ── Acciones ──
            if (isPendiente) _AccionesBar(cuadreId: cuadre.id),
          ],
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
    final children = <Widget>[
      for (final venta in ventas) ...[
        _VentaViewCard(venta: venta),
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
            color: AppColors.primary,
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

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _DetalleHeader extends StatelessWidget {
  const _DetalleHeader({required this.cuadre});

  final Cuadre cuadre;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cuadre.dependienteNombre,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                compactDateFormatter.format(cuadre.fechaTurno),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        _EstadoBadge(estado: cuadre.estado),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final CuadreEstado estado;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      CuadreEstado.aprobado => AppColors.success,
      CuadreEstado.rechazado => AppColors.danger,
      CuadreEstado.pendiente => AppColors.warning,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          estado.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selected ? AppColors.primary : AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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
          subtitle: Text(
            '${venta.items.length} ${venta.items.length == 1 ? 'producto' : 'productos'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Text(
            formatCurrency(venta.total),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
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
                      style: Theme.of(context).textTheme.bodyMedium,
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
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: AppColors.primary,
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
                color: AppColors.primary,
              ),
            ),
          ],
        ),
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
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.comment_outlined,
                  color: AppColors.danger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comentario del jefe',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
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

class _AccionesBar extends ConsumerWidget {
  const _AccionesBar({required this.cuadreId});

  final String cuadreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarRechazo(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarAprobacion(context, ref),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

    if (ok == true) {
      ref.read(cuadreControllerProvider.notifier).confirmarCuadre(cuadreId);
      if (context.mounted) context.go('/admin/cuadres');
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
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Rechazar'),
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();

    if (comment != null && comment.isNotEmpty) {
      ref
          .read(cuadreControllerProvider.notifier)
          .rechazarCuadre(cuadreId, comment);
      if (context.mounted) context.go('/admin/cuadres');
    }
  }
}

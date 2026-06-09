import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/cuadre_item.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../providers/cuadre_provider.dart';

class CuadreDetalleScreen extends ConsumerStatefulWidget {
  const CuadreDetalleScreen({super.key, required this.cuadreId});

  final String cuadreId;

  @override
  ConsumerState<CuadreDetalleScreen> createState() =>
      _CuadreDetalleScreenState();
}

class _CuadreDetalleScreenState extends ConsumerState<CuadreDetalleScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final cuadres = ref.watch(cuadreControllerProvider);
    final cuadre = cuadres
        .where((c) => c.id == widget.cuadreId)
        .firstOrNull;

    if (cuadre == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del cuadre')),
        body: const Center(child: Text('Cuadre no encontrado')),
      );
    }

    final isPendiente = cuadre.estado == CuadreEstado.pendiente;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del cuadre'),
        leading: IconButton(
          onPressed: () => context.go('/admin/cuadres'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          if (isPendiente)
            IconButton(
              onPressed: () => setState(() => _editMode = !_editMode),
              icon: Icon(
                _editMode ? Icons.close_rounded : Icons.edit_rounded,
              ),
              tooltip: _editMode ? 'Cancelar edición' : 'Modificar',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  _DetalleHeader(cuadre: cuadre),
                  const SizedBox(height: 20),
                  if (_editMode) ...[
                    for (final item in cuadre.items) ...[
                      _ItemEditCard(
                        cuadreId: cuadre.id,
                        item: item,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _AddItemButton(
                      cuadreId: cuadre.id,
                      onAdd: (item) => ref
                          .read(cuadreControllerProvider.notifier)
                          .agregarItemCuadre(cuadre.id, item),
                    ),
                  ] else ...[
                    for (final item in cuadre.items) ...[
                      _ItemViewCard(item: item),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (cuadre.items.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Sin ítems en este cuadre.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _DetalleTotales(cuadre: cuadre),
                  if (cuadre.comentarioJefe != null) ...[
                    const SizedBox(height: 16),
                    _ComentarioJefe(comentario: cuadre.comentarioJefe!),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (isPendiente && !_editMode) _AccionesBar(cuadreId: cuadre.id),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

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

// ─── Ítems vista ──────────────────────────────────────────────────────────────

class _ItemViewCard extends StatelessWidget {
  const _ItemViewCard({required this.item});

  final CuadreItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productoNombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.cantidad} unid. × ${formatCurrency(item.precioUnitario)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(item.subtotal),
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

// ─── Ítems edición ────────────────────────────────────────────────────────────

class _ItemEditCard extends ConsumerWidget {
  const _ItemEditCard({required this.cuadreId, required this.item});

  final String cuadreId;
  final CuadreItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(cuadreControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productoNombre,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCurrency(item.precioUnitario)} c/u',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _QtyControls(
              cantidad: item.cantidad,
              onDecrement: item.cantidad > 1
                  ? () => ctrl.modificarCantidadItem(
                        cuadreId,
                        item.productoId,
                        item.cantidad - 1,
                      )
                  : null,
              onIncrement: () => ctrl.modificarCantidadItem(
                cuadreId,
                item.productoId,
                item.cantidad + 1,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(item.subtotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => ctrl.eliminarItemCuadre(
                    cuadreId,
                    item.productoId,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControls extends StatelessWidget {
  const _QtyControls({
    required this.cantidad,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int cantidad;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 32,
          child: Text(
            '$cantidad',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: SizedBox.square(
          dimension: 30,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ─── Botón agregar ítem ───────────────────────────────────────────────────────

class _AddItemButton extends ConsumerWidget {
  const _AddItemButton({required this.cuadreId, required this.onAdd});

  final String cuadreId;
  final void Function(CuadreItem) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showAddItemSheet(context, ref),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Agregar producto'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref) {
    final productos = ref
        .read(inventarioControllerProvider)
        .productos
        .where((p) => p.activo)
        .toList();

    String? selectedId;
    final cantidadCtrl = TextEditingController(text: '1');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar producto al cuadre',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    hint: const Text('Selecciona un producto'),
                    isExpanded: true,
                    menuMaxHeight: 300,
                    items: productos
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedId = v),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: cantidadCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (selectedId == null) return;
                      final cant =
                          int.tryParse(cantidadCtrl.text.trim()) ?? 0;
                      if (cant <= 0) return;
                      final p =
                          productos.firstWhere((p) => p.id == selectedId);
                      onAdd(
                        CuadreItem(
                          productoId: p.id,
                          productoNombre: p.nombre,
                          cantidad: cant,
                          precioUnitario: p.precio,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(cantidadCtrl.dispose);
  }
}

// ─── Totales ──────────────────────────────────────────────────────────────────

class _DetalleTotales extends StatelessWidget {
  const _DetalleTotales({required this.cuadre});

  final Cuadre cuadre;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cuadre.items.length} '
              '${cuadre.items.length == 1 ? 'producto' : 'productos'} · '
              '${cuadre.totalSalidas} unidades',
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
          formatCurrency(cuadre.valorTotal),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }
}

// ─── Comentario del jefe ──────────────────────────────────────────────────────

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
            Text(
              comentario,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra de acciones ────────────────────────────────────────────────────────

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
        title: const Text('¿Confirmar cuadre?'),
        content: const Text(
          'Se marcará este cuadre como aprobado. '
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
                  '¿Estás seguro? El stock se restaurará '
                  'a los valores previos al turno.',
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

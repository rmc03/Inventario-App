import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../../shared/widgets/stock_badge.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../providers/inventario_provider.dart';

class ProductoDetalleScreen extends ConsumerWidget {
  const ProductoDetalleScreen({
    super.key,
    required this.productId,
    this.isAdmin = true,
  });

  final String productId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selecciona solo el producto por id: evita rebuilds cuando cambia
    // búsqueda, filtros, orden u otros productos del inventario.
    final producto = ref.watch(
      inventarioControllerProvider.select(
        (s) => s.productos.where((p) => p.id == productId).firstOrNull,
      ),
    );

    if (producto == null || !producto.activo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del producto')),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    final descripcion = producto.descripcion?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () =>
                  context.push('/admin/inventario/productos/${producto.id}/editar'),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Editar',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + 80,
          ),
          children: [
            // ─── Foto ────────────────────────────────────────────────────
            DecoratedBox(
              decoration: ShapeDecoration(
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                shadows: AppShadows.subtle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ProductPhoto(
                  url: producto.fotoUrl,
                  size: 188,
                  iconSize: 72,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ─── Nombre ──────────────────────────────────────────────────
            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (descripcion != null && descripcion.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.colors.muted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            // ─── Sección: Producto ────────────────────────────────────────
            _SectionHeader(title: 'PRODUCTO'),
            _GroupedCard(
              children: [
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: producto.categoriaNombre ?? 'Sin categoría',
                ),
                const _CardSeparator(),
                _DetailRow(
                  icon: Icons.paid_outlined,
                  label: 'Precio por Unidad',
                  value: formatCurrency(producto.precio),
                ),
              ],
            ),
            // ─── Sección: Inventario ──────────────────────────────────────
            _SectionHeader(title: 'INVENTARIO'),
            _GroupedCard(
              children: [
                _DetailRow(
                  icon: Icons.inventory_outlined,
                  label: 'Stock disponible',
                  customValue: StockBadge(
                    stock: producto.stockActual,
                    isLow: producto.tieneStockBajo,
                  ),
                ),
                const _CardSeparator(),
                if (isAdmin)
                  _DetailRow(
                    icon: Icons.assessment_outlined,
                    label: 'Valor total',
                    value: formatCurrency(producto.valorTotal),
                  ),
              ],
            ),
            // ─── Ajustar Stock ────────────────────────────────────────────
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.xl),
              _GroupedCard(
                children: [
                  _AjustarStockButton(producto: producto),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              _GroupedCard(
                children: [
                  _DeleteButton(producto: producto),
                ],
              ),
            ],
          ],
        ),
      ),
        ),
      ),
    );
  }
}

// ─── Helpers de sección agrupada estilo iOS ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdBorder,
        ),
        shadows: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.mdBorder,
        child: Column(children: children),
      ),
    );
  }
}

class _CardSeparator extends StatelessWidget {
  const _CardSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: AppSpacing.xxl),
      child: Divider(height: 1, indent: 0),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.customValue,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? customValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          customValue ??
              Text(
                value ?? '',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
        ],
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _confirmDelete(context, ref, producto),
      borderRadius: AppRadii.mdBorder,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Text(
            'Eliminar producto',
            style: TextStyle(
              color: context.colors.danger,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: context.colors.danger,
            size: 42,
          ),
          title: const Text('¿Eliminar producto?'),
          content: Text(
            'Esta acción no se puede deshacer. ¿Deseas eliminar ${producto.nombre}?',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Haptics.warning(context);
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.danger,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      ref
          .read(inventarioControllerProvider.notifier)
          .deleteProducto(producto.id);
      if (context.mounted) {
        context.go('/admin/inventario');
      }
    }
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Botón para Ajustar Stock (dentro de tarjeta)
// ═══════════════════════════════════════════════════════════════════════════

class _AjustarStockButton extends ConsumerWidget {
  const _AjustarStockButton({required this.producto});

  final Producto producto;

  void _showAjustarStockSheet(BuildContext context, Producto producto) {
    Haptics.tap(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AjustarStockSheet(producto: producto),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showAjustarStockSheet(context, producto),
      borderRadius: AppRadii.mdBorder,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Text(
            'Ajustar stock',
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bottom Sheet: Ajustar Stock
// ═══════════════════════════════════════════════════════════════════════════

class _AjustarStockSheet extends ConsumerStatefulWidget {
  const _AjustarStockSheet({required this.producto});

  final Producto producto;

  @override
  ConsumerState<_AjustarStockSheet> createState() => _AjustarStockSheetState();
}


class _AjustarStockSheetState extends ConsumerState<_AjustarStockSheet> {
  late int _ajuste;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ajuste = 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _nuevoStock => widget.producto.stockActual + _ajuste;

  void _incrementar() {
    setState(() => _ajuste++);
    Haptics.tap(context);
  }

  void _decrementar() {
    // No permitir stock negativo
    if (_nuevoStock > 0) {
      setState(() => _ajuste--);
      Haptics.tap(context);
    } else {
      Haptics.warning(context);
    }
  }

  void _setAjuste(int value) {
    setState(() => _ajuste = value);
    Haptics.tap(context);
  }

  Future<void> _aplicarAjuste() async {
    if (_ajuste == 0) {
      Navigator.of(context).pop();
      return;
    }

    // TODO: Obtener el usuario actual del sistema de autenticación
    // Por ahora usamos un usuario de ejemplo
    final usuario = Usuario(
      id: '00000000-0000-4000-9000-000000000001',
      email: 'admin@mypime.com',
      nombre: 'Ruslan Jefe',
      rol: UserRole.admin,
      fotoUrl: null,
      createdAt: DateTime.now(),
    );

    setState(() => _isLoading = true);

    try {
      // Registrar el movimiento
      // Para ajustes manuales: siempre usamos MovimientoTipo.entrada (positivo o negativo)
      // para distinguirlos de las ventas (MovimientoTipo.salida con ventaId)
      ref.read(movimientoControllerProvider.notifier).registrarMovimiento(
            producto: widget.producto,
            usuario: usuario,
            tipo: MovimientoTipo.entrada,
            cantidad: _ajuste, // Puede ser positivo o negativo
            nota: _ajuste > 0 
                ? 'Ajuste manual: +${_ajuste.abs()} unidades'
                : 'Ajuste manual: -${_ajuste.abs()} unidades',
          );

      // Actualizar el stock del producto
      final nuevoProducto = widget.producto.copyWith(
        stockActual: _nuevoStock,
      );
      ref
          .read(inventarioControllerProvider.notifier)
          .upsertProducto(nuevoProducto);

      if (mounted) {
        Haptics.confirm(context);
        Navigator.of(context).pop();
        
        // Mostrar feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _ajuste > 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: context.colors.background,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ajuste > 0
                        ? 'Stock aumentado: +${_ajuste.abs()} unidades'
                        : 'Stock reducido: -${_ajuste.abs()} unidades',
                  ),
                ),
              ],
            ),
            backgroundColor: _ajuste > 0
                ? context.colors.success
                : context.colors.info,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Haptics.warning(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ajustar stock: $e'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final estaAumentando = _ajuste > 0;
    final sinCambios = _ajuste == 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.sm,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajustar stock',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.producto.nombre,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.muted,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Stock Actual ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colors.line.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock actual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.producto.stockActual} ${widget.producto.stockActual == 1 ? 'unidad' : 'unidades'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  if (!sinCambios) ...[
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: context.colors.muted,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Nuevo stock',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.colors.muted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_nuevoStock ${_nuevoStock == 1 ? 'unidad' : 'unidades'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: estaAumentando
                                    ? context.colors.success
                                    : context.colors.info,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Controles de Ajuste ──
            Text(
              'Cantidad a ajustar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Botones de ajuste rápido ──
            Row(
              children: [
                Expanded(
                  child: _QuickAdjustButton(
                    label: '-10',
                    onTap: () => _setAjuste(_ajuste - 10),
                    color: context.colors.info,
                    enabled: _nuevoStock - 10 >= 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAdjustButton(
                    label: '-5',
                    onTap: () => _setAjuste(_ajuste - 5),
                    color: context.colors.info,
                    enabled: _nuevoStock - 5 >= 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAdjustButton(
                    label: '+5',
                    onTap: () => _setAjuste(_ajuste + 5),
                    color: context.colors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAdjustButton(
                    label: '+10',
                    onTap: () => _setAjuste(_ajuste + 10),
                    color: context.colors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Contador principal ──
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sinCambios
                      ? context.colors.line
                      : (estaAumentando
                          ? context.colors.success
                          : context.colors.info),
                  width: 2,
                ),
                boxShadow: AppShadows.subtle,
              ),
              child: Row(
                children: [
                  // Botón decrementar
                  _CounterButton(
                    icon: Icons.remove_rounded,
                    onPressed: _decrementar,
                    enabled: _nuevoStock > 0,
                    color: context.colors.info,
                  ),
                  
                  // Display del ajuste
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _ajuste == 0
                              ? '0'
                              : _ajuste > 0
                                  ? '+$_ajuste'
                                  : '$_ajuste',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: sinCambios
                                    ? context.colors.muted
                                    : (estaAumentando
                                        ? context.colors.success
                                        : context.colors.info),
                                letterSpacing: -1,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _ajuste.abs() == 1 ? 'unidad' : 'unidades',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.colors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón incrementar
                  _CounterButton(
                    icon: Icons.add_rounded,
                    onPressed: _incrementar,
                    color: context.colors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Botón aplicar ──
            FilledButton(
              onPressed: _isLoading || sinCambios ? null : _aplicarAjuste,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: estaAumentando
                    ? context.colors.success
                    : context.colors.info,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          estaAumentando
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sinCambios
                              ? 'Sin cambios'
                              : estaAumentando
                                  ? 'Aumentar stock'
                                  : 'Reducir stock',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

// ═══════════════════════════════════════════════════════════════════════════
// Componentes auxiliares
// ═══════════════════════════════════════════════════════════════════════════

class _QuickAdjustButton extends StatelessWidget {
  const _QuickAdjustButton({
    required this.label,
    required this.onTap,
    required this.color,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? color.withValues(alpha: 0.1)
          : context.colors.muted.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: enabled ? color : context.colors.muted.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? color.withValues(alpha: 0.12)
          : context.colors.muted.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 28,
            color: enabled ? color : context.colors.muted.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

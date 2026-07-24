import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/pago.dart';
import '../providers/venta_provider.dart';

class ConfirmarPagoScreen extends ConsumerStatefulWidget {
  const ConfirmarPagoScreen({super.key});

  @override
  ConsumerState<ConfirmarPagoScreen> createState() => _ConfirmarPagoScreenState();
}

class _ConfirmarPagoScreenState extends ConsumerState<ConfirmarPagoScreen> {
  MetodoPago? _metodoSeleccionado;

  bool get _esValido => _metodoSeleccionado != null;

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaEnCursoProvider);
    if (venta == null) return const SizedBox.shrink();

    final total = venta.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmar pago',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Resumen de la venta (scrolleable) ──
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                itemCount: venta.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = venta.items[index];
                  // Card individual por producto para mejor separación visual
                  return Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del producto - destacado
                              Text(
                                item.productoNombre,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.ink,
                                  letterSpacing: -0.3,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Cantidad × Precio unitario - secundario
                              Text(
                                '${item.cantidad} \u00d7 ${formatCurrency(item.precioUnitario)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: context.colors.muted,
                                  letterSpacing: -0.2,
                                  // Tabular figures para alineación de números
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Precio total - máximo énfasis
                        Text(
                          formatCurrency(item.subtotal),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                            letterSpacing: -0.5,
                            // Tabular figures para alineación vertical
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Total fijo (siempre visible) con máximo énfasis ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: context.colors.surfaceSecondary,
                border: Border(
                  top: BorderSide(
                    color: context.colors.line.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Total con máximo énfasis visual
                  Text(
                    formatCurrency(total),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                      letterSpacing: -1,
                      height: 1.1,
                      // Tabular figures para números
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Método de pago ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Método de pago',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetodoCard(
                          metodo: MetodoPago.efectivo,
                          seleccionado: _metodoSeleccionado == MetodoPago.efectivo,
                          onTap: () => setState(() {
                            _metodoSeleccionado =
                                _metodoSeleccionado == MetodoPago.efectivo
                                    ? null
                                    : MetodoPago.efectivo;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetodoCard(
                          metodo: MetodoPago.transferencia,
                          seleccionado: _metodoSeleccionado == MetodoPago.transferencia,
                          onTap: () => setState(() {
                            _metodoSeleccionado =
                                _metodoSeleccionado == MetodoPago.transferencia
                                    ? null
                                    : MetodoPago.transferencia;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón confirmar con touch target adecuado ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 56, // Touch target mínimo 44pt → 56px cumple
                width: double.infinity,
                child: FilledButton(
                  onPressed: _esValido
                      ? () {
                          Haptics.confirm(context);
                          _confirmar(total);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    disabledBackgroundColor: context.colors.muted.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Confirmar y registrar venta',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmar(double total) {
    final venta = ref.read(ventaEnCursoProvider);
    if (venta == null) return;

    final pagos = <Pago>[];
    if (_metodoSeleccionado == MetodoPago.efectivo) {
      pagos.add(Pago(metodo: MetodoPago.efectivo, monto: total));
    } else if (_metodoSeleccionado == MetodoPago.transferencia) {
      pagos.add(Pago(metodo: MetodoPago.transferencia, monto: total));
    }

    ref.read(ventaEnCursoProvider.notifier).completarVentaConPagos(pagos);
    if (mounted) Navigator.of(context).pop(true);
  }
}

class _MetodoCard extends StatefulWidget {
  const _MetodoCard({
    required this.metodo,
    required this.seleccionado,
    required this.onTap,
  });

  final MetodoPago metodo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  State<_MetodoCard> createState() => _MetodoCardState();
}

class _MetodoCardState extends State<_MetodoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // Touch target: 20 + 32 + 8 + texto + 8 + 22 + 20 = ~110pt cumple 44pt
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.seleccionado
                ? context.colors.primary.withValues(alpha: 0.08)
                : context.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.seleccionado ? context.colors.primary : context.colors.line,
              width: widget.seleccionado ? 2 : 1,
            ),
            // Sombra sutil cuando seleccionado
            boxShadow: widget.seleccionado
                ? [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                widget.metodo.icon,
                size: 32,
                color: widget.seleccionado ? context.colors.primary : context.colors.muted,
              ),
              const SizedBox(height: 8),
              Text(
                widget.metodo.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: widget.seleccionado ? context.colors.primary : context.colors.ink,
                  fontWeight: widget.seleccionado ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.seleccionado ? context.colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.seleccionado ? context.colors.primary : context.colors.line,
                    width: 2,
                  ),
                ),
                child: widget.seleccionado
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

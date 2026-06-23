import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
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
      appBar: AppBar(title: const Text('Confirmar pago')),
      body: SafeArea(
        child: Column(
          children: [
            // ── Resumen de la venta (scrolleable con total fijo) ──
            Expanded(
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        children: venta.items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productoNombre,
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.cantidad} \u00d7 ${formatCurrency(item.precioUnitario)}',
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
                            )
                            .toList(),
                      ),
                    ),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            formatCurrency(total),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Método de pago ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Método de pago',
                    style: Theme.of(context).textTheme.titleMedium,
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

            // ── Botón confirmar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _esValido ? () => _confirmar(total) : null,
                  child: const Text('Confirmar y registrar venta'),
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

class _MetodoCard extends StatelessWidget {
  const _MetodoCard({
    required this.metodo,
    required this.seleccionado,
    required this.onTap,
  });

  final MetodoPago metodo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.line,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              metodo.icon,
              size: 32,
              color: seleccionado ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              metodo.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: seleccionado ? AppColors.primary : AppColors.ink,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: seleccionado ? AppColors.primary : AppColors.line,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

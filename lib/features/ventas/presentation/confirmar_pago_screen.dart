import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Control de pagos múltiples
  final List<Pago> _pagos = [];
  double _montoEfectivo = 0.0;
  double _montoTransferencia = 0.0;
  
  // Calculadora de cambio
  final _efectivoRecibidoController = TextEditingController();
  double _efectivoRecibido = 0.0;
  
  // UI state
  bool _mostrarCalculadora = false;

  @override
  void dispose() {
    _efectivoRecibidoController.dispose();
    super.dispose();
  }

  double get _totalVenta {
    final venta = ref.read(ventaEnCursoProvider);
    return venta?.total ?? 0.0;
  }

  double get _montoAsignado => _montoEfectivo + _montoTransferencia;
  double get _montoPendiente => _totalVenta - _montoAsignado;
  double get _cambio => _efectivoRecibido - _montoEfectivo;

  bool get _esValido {
    // Debe cubrir el total y el cambio debe ser válido si hay efectivo
    if (_montoAsignado < _totalVenta) return false;
    if (_montoEfectivo > 0 && _efectivoRecibido < _montoEfectivo) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaEnCursoProvider);
    if (venta == null) return const SizedBox.shrink();

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Productos
                    ...venta.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
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
                                    Text(
                                      '${item.cantidad} \u00d7 ${formatCurrency(item.precioUnitario)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: context.colors.muted,
                                        letterSpacing: -0.2,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                formatCurrency(item.subtotal),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primary,
                                  letterSpacing: -0.5,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Panel de pago combinado ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(
                  top: BorderSide(
                    color: context.colors.line.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total de la venta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceSecondary,
                      border: Border(
                        bottom: BorderSide(
                          color: context.colors.line.withValues(alpha: 0.2),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.colors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          formatCurrency(_totalVenta),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colors.primary,
                            letterSpacing: -0.8,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          'Método de pago',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colors.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Input efectivo
                        _MontoInput(
                          label: 'Efectivo',
                          icon: Icons.payments_outlined,
                          monto: _montoEfectivo,
                          montoPendiente: _montoPendiente,
                          onChanged: (valor) {
                            setState(() {
                              _montoEfectivo = valor;
                              _mostrarCalculadora = valor > 0;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Input transferencia
                        _MontoInput(
                          label: 'Transferencia',
                          icon: Icons.account_balance_outlined,
                          monto: _montoTransferencia,
                          montoPendiente: _montoPendiente,
                          onChanged: (valor) {
                            setState(() => _montoTransferencia = valor);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Resumen de pago
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _montoPendiente <= 0
                                ? context.colors.success.withValues(alpha: 0.08)
                                : context.colors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _montoPendiente <= 0
                                  ? context.colors.success.withValues(alpha: 0.3)
                                  : context.colors.warning.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _montoPendiente > 0 ? 'Pendiente' : _montoPendiente < 0 ? 'Excedente' : 'Pagado',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _montoPendiente <= 0
                                      ? context.colors.success
                                      : context.colors.warning,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                formatCurrency(_montoPendiente.abs()),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _montoPendiente <= 0
                                      ? context.colors.success
                                      : context.colors.warning,
                                  letterSpacing: -0.4,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Calculadora de cambio (solo si hay efectivo)
                        if (_mostrarCalculadora && _montoEfectivo > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.colors.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calculate_outlined,
                                      size: 20,
                                      color: context.colors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Calculadora de cambio',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.ink,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _efectivoRecibidoController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.ink,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Efectivo recibido',
                                    labelStyle: TextStyle(
                                      fontSize: 14,
                                      color: context.colors.muted,
                                    ),
                                    prefixText: '\$',
                                    prefixStyle: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.muted,
                                    ),
                                    filled: true,
                                    fillColor: context.colors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: context.colors.line,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: context.colors.line,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: context.colors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (valor) {
                                    setState(() {
                                      _efectivoRecibido = double.tryParse(valor) ?? 0.0;
                                    });
                                  },
                                ),
                                if (_efectivoRecibido > 0) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _cambio >= 0
                                          ? context.colors.success.withValues(alpha: 0.12)
                                          : context.colors.danger.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Cambio a devolver',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _cambio >= 0
                                                ? context.colors.success
                                                : context.colors.danger,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        Text(
                                          formatCurrency(_cambio.abs()),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: _cambio >= 0
                                                ? context.colors.success
                                                : context.colors.danger,
                                            letterSpacing: -0.6,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_cambio < 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '⚠️ El efectivo recibido es insuficiente',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.danger,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botón confirmar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _esValido
                            ? () {
                                Haptics.confirm(context);
                                _confirmar();
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _esValido ? 'Confirmar y registrar venta' : 'Complete el pago',
                              style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  void _confirmar() {
    final venta = ref.read(ventaEnCursoProvider);
    if (venta == null) return;

    final pagos = <Pago>[];
    
    if (_montoEfectivo > 0) {
      pagos.add(Pago(
        metodo: MetodoPago.efectivo,
        monto: _montoEfectivo,
        efectivoRecibido: _efectivoRecibido > 0 ? _efectivoRecibido : null,
        cambio: _efectivoRecibido > 0 ? _cambio : null,
      ));
    }
    
    if (_montoTransferencia > 0) {
      pagos.add(Pago(
        metodo: MetodoPago.transferencia,
        monto: _montoTransferencia,
      ));
    }

    ref.read(ventaEnCursoProvider.notifier).completarVentaConPagos(pagos);
    if (mounted) Navigator.of(context).pop(true);
  }
}

// Widget para input de monto (efectivo o transferencia)
class _MontoInput extends StatefulWidget {
  const _MontoInput({
    required this.label,
    required this.icon,
    required this.monto,
    required this.montoPendiente,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double monto;
  final double montoPendiente;
  final ValueChanged<double> onChanged;

  @override
  State<_MontoInput> createState() => _MontoInputState();
}

class _MontoInputState extends State<_MontoInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.monto > 0 ? widget.monto.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: context.colors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            // Botón rápido para pagar el pendiente
            if (widget.montoPendiente > 0)
              TextButton(
                onPressed: () {
                  final nuevoMonto = widget.monto + widget.montoPendiente;
                  _controller.text = nuevoMonto.toStringAsFixed(2);
                  widget.onChanged(nuevoMonto);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Pagar pendiente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.colors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '\$',
            prefixStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
            ),
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: context.colors.line,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: context.colors.line,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: context.colors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: widget.monto > 0
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.colors.muted,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged(0);
                    },
                  )
                : null,
          ),
          onChanged: (valor) {
            final monto = double.tryParse(valor) ?? 0.0;
            widget.onChanged(monto);
          },
        ),
      ],
    );
  }
}

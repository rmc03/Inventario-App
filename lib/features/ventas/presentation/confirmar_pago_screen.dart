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

enum ModoPago {
  efectivo,
  transferencia,
  mixto,
}

class _ConfirmarPagoScreenState extends ConsumerState<ConfirmarPagoScreen>
    with TickerProviderStateMixin {
  // Modo de pago seleccionado
  ModoPago _modo = ModoPago.efectivo;

  late final AnimationController _entranceController;
  List<Animation<double>> _itemAnimations = [];
  
  // Montos por método
  double _montoEfectivo = 0.0;
  double _montoTransferencia = 0.0;
  
  // Calculadora de cambio (opcional)
  final _efectivoRecibidoController = TextEditingController();
  double _efectivoRecibido = 0.0;
  bool _mostrarCalculadoraEfectivo = false;
  
  // Controllers para modo mixto
  final _efectivoMixtoController = TextEditingController();
  final _transferenciaMixtoController = TextEditingController();

  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarModoEfectivo();
    });
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _efectivoRecibidoController.dispose();
    _efectivoMixtoController.dispose();
    _transferenciaMixtoController.dispose();
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
    if (_isConfirming) return false;
    if (_modo == ModoPago.efectivo || _modo == ModoPago.transferencia) {
      return true;
    }
    return _montoAsignado == _totalVenta;
  }

  void _actualizarModoEfectivo() {
    setState(() {
      _montoEfectivo = _totalVenta;
      _montoTransferencia = 0.0;
      _efectivoMixtoController.clear();
      _transferenciaMixtoController.clear();
      _efectivoRecibidoController.clear();
      _efectivoRecibido = 0.0;
      _mostrarCalculadoraEfectivo = false;
    });
  }

  void _actualizarModoTransferencia() {
    setState(() {
      _montoEfectivo = 0.0;
      _montoTransferencia = _totalVenta;
      _efectivoMixtoController.clear();
      _transferenciaMixtoController.clear();
      _efectivoRecibidoController.clear();
      _efectivoRecibido = 0.0;
      _mostrarCalculadoraEfectivo = false;
    });
  }

  void _actualizarModoMixto() {
    setState(() {
      _montoEfectivo = 0.0;
      _montoTransferencia = 0.0;
      _efectivoMixtoController.clear();
      _transferenciaMixtoController.clear();
      _efectivoRecibidoController.clear();
      _efectivoRecibido = 0.0;
      _mostrarCalculadoraEfectivo = false;
    });
  }

  Widget _buildModoContent() {
    switch (_modo) {
      case ModoPago.efectivo:
        return KeyedSubtree(
          key: const ValueKey('efectivo'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón completo "Calcular efectivo"
              InkWell(
                onTap: () => setState(() => _mostrarCalculadoraEfectivo = !_mostrarCalculadoraEfectivo),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.line.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: context.colors.ink,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Calcular efectivo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calculate_outlined,
                        size: 20,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _CalculadoraCambio(
                    controller: _efectivoRecibidoController,
                    montoEfectivo: _montoEfectivo,
                    onChanged: (valor) => setState(() => _efectivoRecibido = valor),
                  ),
                ),
                crossFadeState: _mostrarCalculadoraEfectivo
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        );

      case ModoPago.transferencia:
        return KeyedSubtree(
          key: const ValueKey('transferencia'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón/Contenedor del mismo tamaño para consistencia visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.line.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 20,
                      color: context.colors.ink,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pago por transferencia',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: context.colors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case ModoPago.mixto:
        return KeyedSubtree(
          key: const ValueKey('mixto'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CampoMontoMixto(
                label: 'Efectivo', icon: Icons.payments_outlined,
                controller: _efectivoMixtoController,
                monto: _montoEfectivo, otroMonto: _montoTransferencia,
                totalVenta: _totalVenta,
                onChanged: (valor) => setState(() => _montoEfectivo = valor),
                onCompletarResto: () {
                  final resto = _totalVenta - _montoTransferencia;
                  _efectivoMixtoController.text = resto > 0 ? resto.toStringAsFixed(2) : '0.00';
                  setState(() => _montoEfectivo = resto > 0 ? resto : 0.0);
                },
              ),
              const SizedBox(height: 12),
              _CampoMontoMixto(
                label: 'Transferencia', icon: Icons.account_balance_outlined,
                controller: _transferenciaMixtoController,
                monto: _montoTransferencia, otroMonto: _montoEfectivo,
                totalVenta: _totalVenta,
                onChanged: (valor) => setState(() => _montoTransferencia = valor),
                onCompletarResto: () {
                  final resto = _totalVenta - _montoEfectivo;
                  _transferenciaMixtoController.text = resto > 0 ? resto.toStringAsFixed(2) : '0.00';
                  setState(() => _montoTransferencia = resto > 0 ? resto : 0.0);
                },
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _montoPendiente == 0
                      ? context.colors.success.withValues(alpha: 0.08)
                      : context.colors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _montoPendiente == 0
                        ? context.colors.success.withValues(alpha: 0.3)
                        : context.colors.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _montoPendiente == 0 ? 'Pagado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: _montoPendiente == 0 ? context.colors.success : context.colors.warning,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      formatCurrency(_montoPendiente == 0 ? _totalVenta : _montoPendiente.abs()),
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: _montoPendiente == 0 ? context.colors.success : context.colors.warning,
                        letterSpacing: -0.4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_esValido && (_montoEfectivo > 0 || _montoTransferencia > 0))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _montoPendiente > 0
                        ? 'Falta ${formatCurrency(_montoPendiente)} por asignar'
                        : 'Sobra ${formatCurrency(_montoPendiente.abs())}',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: context.colors.warning, letterSpacing: -0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_montoEfectivo > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: context.colors.muted),
                    const SizedBox(width: 6),
                    Text('Cambio sobre efectivo', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: context.colors.ink, letterSpacing: -0.2,
                    )),
                    const Spacer(),
                    Semantics(
                      label: 'Abrir calculadora de cambio para efectivo', button: true,
                      child: InkWell(
                        onTap: () => setState(() => _mostrarCalculadoraEfectivo = !_mostrarCalculadoraEfectivo),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.calculate_outlined, size: 18, color: context.colors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _CalculadoraCambio(
                      controller: _efectivoRecibidoController,
                      montoEfectivo: _montoEfectivo,
                      onChanged: (valor) => setState(() => _efectivoRecibido = valor),
                    ),
                  ),
                  crossFadeState: _mostrarCalculadoraEfectivo
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaEnCursoProvider);
    if (venta == null) return const SizedBox.shrink();

    if (_itemAnimations.length != venta.items.length) {
      _itemAnimations = List.generate(venta.items.length, (i) {
        return Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(i * 0.08, 1.0, curve: Curves.easeOutCubic),
          ),
        );
      });
    }

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
                    ...venta.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return FadeTransition(
                        opacity: _itemAnimations[i],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(_itemAnimations[i]),
                          child: Padding(
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
                        const SizedBox(height: 12),

                        // Selector de modo (Efectivo / Transferencia / Mixto)
                        Row(
                          children: [
                            Expanded(
                              child: _ModoButton(
                                label: 'Efectivo',
                                icon: Icons.payments_outlined,
                                isSelected: _modo == ModoPago.efectivo,
                                onTap: () {
                                  setState(() {
                                    _modo = ModoPago.efectivo;
                                    _actualizarModoEfectivo();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModoButton(
                                label: 'Transferencia',
                                icon: Icons.account_balance_outlined,
                                isSelected: _modo == ModoPago.transferencia,
                                onTap: () {
                                  setState(() {
                                    _modo = ModoPago.transferencia;
                                    _actualizarModoTransferencia();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModoButton(
                                label: 'Mixto',
                                icon: Icons.compare_arrows_outlined,
                                isSelected: _modo == ModoPago.mixto,
                                onTap: () {
                                  setState(() {
                                    _modo = ModoPago.mixto;
                                    _actualizarModoMixto();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildModoContent(),
                          ),
                        ),
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
                        onPressed: (_esValido && !_isConfirming)
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: _isConfirming
                              ? Row(
                                  key: const ValueKey('confirming'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 24, color: Colors.white),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Venta registrada',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  key: const ValueKey('idle'),
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

    setState(() => _isConfirming = true);

    ref.read(ventaEnCursoProvider.notifier).completarVentaConPagos(pagos);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ════════════════════════════════════════════════════════════════════════════

/// Botón para seleccionar el modo de pago (Efectivo/Transferencia/Mixto)
class _ModoButton extends StatelessWidget {
  const _ModoButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.primary : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.line,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : context.colors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : context.colors.ink,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de entrada para montos en modo mixto
class _CampoMontoMixto extends StatelessWidget {
  const _CampoMontoMixto({
    required this.label,
    required this.icon,
    required this.controller,
    required this.monto,
    required this.otroMonto,
    required this.totalVenta,
    required this.onChanged,
    required this.onCompletarResto,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final double monto;
  final double otroMonto;
  final double totalVenta;
  final ValueChanged<double> onChanged;
  final VoidCallback onCompletarResto;

  bool get _mostrarIconoCompletar {
    // Mostrar ícono si:
    // - el otro campo tiene monto > 0
    // - este campo está en 0
    // - el otro campo es menor al total
    return otroMonto > 0 && monto == 0 && otroMonto < totalVenta;
  }

  @override
  Widget build(BuildContext context) {
    final montoRestante = totalVenta - otroMonto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: context.colors.ink,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            // Ícono para completar el resto (solo visible en las condiciones especificadas)
            if (_mostrarIconoCompletar)
              Semantics(
                label: 'Completar con ${formatCurrency(montoRestante)} en $label',
                button: true,
                child: InkWell(
                  onTap: onCompletarResto,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.money_outlined,
                      size: 20,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
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
            suffixIcon: monto > 0
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.colors.muted,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged(0);
                    },
                  )
                : null,
          ),
          onChanged: (valor) {
            final monto = double.tryParse(valor) ?? 0.0;
            onChanged(monto);
          },
        ),
      ],
    );
  }
}

/// Calculadora de cambio (opcional, para efectivo)
class _CalculadoraCambio extends StatelessWidget {
  const _CalculadoraCambio({
    required this.controller,
    required this.montoEfectivo,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double montoEfectivo;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final efectivoRecibido = double.tryParse(controller.text) ?? 0.0;
    final cambio = efectivoRecibido - montoEfectivo;

    return Container(
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
          TextFormField(
            controller: controller,
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
              onChanged(double.tryParse(valor) ?? 0.0);
            },
          ),
          if (efectivoRecibido > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cambio >= 0
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
                      color: cambio >= 0
                          ? context.colors.success
                          : context.colors.danger,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    formatCurrency(cambio >= 0 ? cambio : 0),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cambio >= 0
                          ? context.colors.success
                          : context.colors.danger,
                      letterSpacing: -0.6,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (cambio < 0)
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
    );
  }
}

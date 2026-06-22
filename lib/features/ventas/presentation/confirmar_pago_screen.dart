import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/pago.dart';
import '../providers/venta_provider.dart';

class ConfirmarPagoScreen extends ConsumerStatefulWidget {
  const ConfirmarPagoScreen({super.key});

  @override
  ConsumerState<ConfirmarPagoScreen> createState() => _ConfirmarPagoScreenState();
}

class _ConfirmarPagoScreenState extends ConsumerState<ConfirmarPagoScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _efectivoRecibidoCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _efectivoRecibidoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venta = ref.watch(ventaEnCursoProvider);
    if (venta == null) return const SizedBox.shrink();

    final total = venta.total;
    // Métodos soportados
    final metodos = ['efectivo', 'tarjeta', 'transferencia'];
    for (final m in metodos) {
      _controllers.putIfAbsent(m, () => TextEditingController(text: ''));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pago')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Total a pagar: ${formatCurrency(total)}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final m in metodos) ...[
                TextField(
                  controller: _controllers[m],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Pago: ${m[0].toUpperCase()}${m.substring(1)}'),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _efectivoRecibidoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Efectivo recibido (opcional)'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Construir lista de pagos
                    final pagos = <Pago>[];
                    double sum = 0.0;
                    for (final m in metodos) {
                      final text = (_controllers[m]?.text ?? '').trim();
                      if (text.isEmpty) continue;
                      final value = double.tryParse(text.replaceAll(',', '')) ?? 0.0;
                      if (value <= 0) continue;
                      pagos.add(Pago(metodo: m, monto: value));
                      sum += value;
                    }

                    // Si no se ingresó nada, asumir pago en efectivo completo
                    if (pagos.isEmpty) {
                      pagos.add(Pago(metodo: 'efectivo', monto: total));
                      sum = total;
                    }

                    // Validación básica: suma de pagos debe cubrir el total
                    if (sum < total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La suma de pagos no cubre el total')),
                      );
                      return;
                    }

                    // Si efectivo recibido se indicó, añadirlo al pago efectivo
                    final efectivoText = _efectivoRecibidoCtrl.text.trim();
                    if (efectivoText.isNotEmpty) {
                      final received = double.tryParse(efectivoText.replaceAll(',', '')) ?? 0.0;
                      if (received > 0) {
                        final idx = pagos.indexWhere((p) => p.metodo == 'efectivo');
                        if (idx != -1) {
                          pagos[idx] = Pago(metodo: pagos[idx].metodo, monto: pagos[idx].monto, efectivoRecibido: received);
                        } else {
                          pagos.add(Pago(metodo: 'efectivo', monto: 0.0, efectivoRecibido: received));
                        }
                      }
                    }

                    // Completar la venta
                    ref.read(ventaEnCursoProvider.notifier).completarVentaConPagos(pagos);
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Confirmar y registrar venta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

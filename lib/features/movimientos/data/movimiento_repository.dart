import 'dart:async';

import '../../../shared/models/movimiento.dart';

class MovimientoRepository {
  MovimientoRepository()
    : _movimientos = [
        Movimiento(
          id: 'mov-001',
          productoId: 'prod-casco',
          productoNombre: 'Casco Integral Shoei GT-Air II',
          usuarioId: '00000000-0000-4000-9000-000000000002',
          usuarioNombre: 'Dependiente Demo',
          tipo: MovimientoTipo.salida,
          cantidad: 1,
          nota: 'Venta de mostrador',
          fecha: DateTime.now().subtract(const Duration(hours: 2)),
          synced: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Movimiento(
          id: 'mov-002',
          productoId: 'prod-aceite',
          productoNombre: 'Aceite Motul 5100 10W-40',
          usuarioId: '00000000-0000-4000-9000-000000000002',
          usuarioNombre: 'Dependiente Demo',
          tipo: MovimientoTipo.entrada,
          cantidad: 10,
          nota: 'Reposición',
          fecha: DateTime.now().subtract(const Duration(hours: 1)),
          synced: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

  final List<Movimiento> _movimientos;
  final StreamController<List<Movimiento>> _controller = StreamController<List<Movimiento>>.broadcast();

  Stream<List<Movimiento>> get movimientosStream => _controller.stream;

  List<Movimiento> fetchMovimientos() {
    final sorted = [..._movimientos]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    // Ensure listeners have initial state
    try {
      _controller.add(List.unmodifiable(sorted));
    } catch (_) {}
    return List.unmodifiable(sorted);
  }

  void addMovimiento(Movimiento movimiento) {
    _movimientos.insert(0, movimiento);
    try {
      _controller.add(List.unmodifiable(_movimientos));
    } catch (_) {}
  }

  void dispose() {
    try {
      _controller.close();
    } catch (_) {}
  }
}

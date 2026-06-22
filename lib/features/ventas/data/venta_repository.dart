import 'dart:async';

import '../../../shared/models/venta.dart';

class VentaRepository {
  VentaRepository();

  final List<Venta> _ventas = [];
  final _ventasController = StreamController<List<Venta>>.broadcast();

  Stream<List<Venta>> watchVentas() => _ventasController.stream;

  List<Venta> fetchVentas() => List.unmodifiable(_ventas);

  void addVenta(Venta venta) {
    _ventas.add(venta);
    _notify();
  }

  void updateVenta(Venta venta) {
    final index = _ventas.indexWhere((v) => v.id == venta.id);
    if (index != -1) {
      _ventas[index] = venta;
      _notify();
    }
  }

  void deleteVenta(String id) {
    _ventas.removeWhere((v) => v.id == id);
    _notify();
  }

  void clear() {
    _ventas.clear();
    _notify();
  }

  void _notify() {
    _ventasController.add(fetchVentas());
  }

  void dispose() {
    _ventasController.close();
  }
}

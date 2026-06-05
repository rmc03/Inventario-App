import '../../../shared/models/movimiento.dart';

class MovimientoRepository {
  MovimientoRepository()
    : _movimientos = [
        Movimiento(
          id: 'mov-001',
          productoId: 'prod-laptop',
          productoNombre: 'Laptop Dell Inspiron 15',
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
          productoId: 'prod-keyboard',
          productoNombre: 'Teclado Inalámbrico Logitech',
          usuarioId: '00000000-0000-4000-9000-000000000002',
          usuarioNombre: 'Dependiente Demo',
          tipo: MovimientoTipo.entrada,
          cantidad: 5,
          nota: 'Reposición',
          fecha: DateTime.now().subtract(const Duration(hours: 1)),
          synced: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

  final List<Movimiento> _movimientos;

  List<Movimiento> fetchMovimientos() {
    final sorted = [..._movimientos]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(sorted);
  }

  void addMovimiento(Movimiento movimiento) {
    _movimientos.insert(0, movimiento);
  }
}

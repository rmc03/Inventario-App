import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/cuadre_item.dart';
import '../../../shared/models/venta.dart';
import '../../../shared/models/pago.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../../../shared/models/movimiento.dart';
import '../data/venta_repository.dart';

final ventaRepositoryProvider = Provider<VentaRepository>((ref) {
  return VentaRepository();
});

// Provider para la lista de ventas completadas del turno actual
final ventasDelTurnoProvider =
    NotifierProvider<VentasDelTurnoController, List<Venta>>(
  VentasDelTurnoController.new,
);

class VentasDelTurnoController extends Notifier<List<Venta>> {
  VentaRepository get _repo => ref.read(ventaRepositoryProvider);

  @override
  List<Venta> build() {
    return _repo.fetchVentas();
  }

  void addVentaCompletada(Venta venta) {
    _repo.addVenta(venta);
    state = _repo.fetchVentas();
  }

  void removeVenta(String id) {
    _repo.deleteVenta(id);
    state = _repo.fetchVentas();
  }

  void clearVentas() {
    _repo.clear();
    state = _repo.fetchVentas();
  }
}

// Provider para la venta que se está construyendo actualmente (POS)
final ventaEnCursoProvider =
    NotifierProvider<VentaEnCursoController, Venta?>(VentaEnCursoController.new);

class VentaEnCursoController extends Notifier<Venta?> {
  @override
  Venta? build() => null;

  void iniciarVenta() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    state = Venta(
      id: const Uuid().v4(),
      dependienteId: user.id,
      dependienteNombre: user.nombre,
      dependienteFotoUrl: user.fotoUrl,
      fecha: DateTime.now(),
      createdAt: DateTime.now(),
      estado: VentaEstado.enCurso,
      items: [],
    );
  }

  void agregarProducto(CuadreItem newItem) {
    if (state == null) return;
    final items = [...state!.items];
    final idx = items.indexWhere((i) => i.productoId == newItem.productoId);

    if (idx == -1) {
      items.add(newItem);
    } else {
      final existing = items[idx];
      items[idx] = existing.copyWith(
        cantidad: existing.cantidad + newItem.cantidad,
      );
    }
    state = state!.copyWith(items: items);
  }

  void actualizarCantidadItem(String productoId, int nuevaCantidad) {
    if (state == null) return;
    final items = [...state!.items];
    final idx = items.indexWhere((i) => i.productoId == productoId);
    if (idx == -1) return;

    if (nuevaCantidad <= 0) {
      items.removeAt(idx);
    } else {
      final existing = items[idx];
      items[idx] = existing.copyWith(cantidad: nuevaCantidad);
    }
    state = state!.copyWith(items: items);
  }

  void eliminarItem(String productoId) {
    if (state == null) return;
    final items = state!.items.where((i) => i.productoId != productoId).toList();
    state = state!.copyWith(items: items);
  }

  /// Completa la venta: la añade al historial del turno, descuenta el stock real y registra los movimientos.
  void completarVenta() {
    if (state == null || state!.items.isEmpty) return;
    completarVentaConPagos([]);
  }
  /// Completa la venta con la lista de pagos (soporta split payments).
  void completarVentaConPagos(List<Pago> pagos) {
    if (state == null || state!.items.isEmpty) return;

    final venta = state!.copyWith(
      estado: VentaEstado.completada,
      fecha: DateTime.now(),
      pagos: pagos,
    );

    // 1. Añadir al historial del turno actual
    ref.read(ventasDelTurnoProvider.notifier).addVentaCompletada(venta);

    // 2. Descontar stock y registrar movimientos
    final inv = ref.read(inventarioControllerProvider.notifier);
    final movRepo = ref.read(movimientoRepositoryProvider);

    for (final item in venta.items) {
      // Registrar movimiento de salida
      movRepo.addMovimiento(
        Movimiento(
          id: const Uuid().v4(),
          productoId: item.productoId,
          productoNombre: item.productoNombre,
          usuarioId: venta.dependienteId,
          usuarioNombre: venta.dependienteNombre,
          usuarioFotoUrl: venta.dependienteFotoUrl,
          tipo: MovimientoTipo.salida,
          cantidad: item.cantidad,
          fecha: venta.fecha,
          nota: 'Venta POS #${venta.id.substring(0, 8)}',
          createdAt: DateTime.now(),
        ),
      );

      // Aplicar al inventario (descuenta el stock)
      inv.applyMovimiento(
        productoId: item.productoId,
        tipo: MovimientoTipo.salida,
        cantidad: item.cantidad,
      );
    }

    // 3. Limpiar la venta en curso
    state = null;
  }

  void cancelarVenta() {
    state = null;
  }
}

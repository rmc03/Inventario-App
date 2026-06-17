import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cuadre_item.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';

import '../data/turno_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import 'package:uuid/uuid.dart';

final turnoRepositoryProvider = Provider<TurnoRepository>((ref) {
  return TurnoRepository();
});

final turnoControllerProvider = NotifierProvider<TurnoController, TurnoState>(
  TurnoController.new,
);

class TurnoState {
  const TurnoState({
    this.estaActivo = false,
    this.horaInicio,
    this.items = const [],
    this.cuadreEnviadoHoy = false,
  });

  final bool estaActivo;
  final DateTime? horaInicio;
  final List<CuadreItem> items;
  final bool cuadreEnviadoHoy;

  double get valorTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get totalUnidades =>
      items.fold(0, (sum, item) => sum + item.cantidad);

  TurnoState copyWith({
    bool? estaActivo,
    DateTime? horaInicio,
    List<CuadreItem>? items,
    bool? cuadreEnviadoHoy,
  }) =>
      TurnoState(
        estaActivo: estaActivo ?? this.estaActivo,
        horaInicio: horaInicio ?? this.horaInicio,
        items: items ?? this.items,
        cuadreEnviadoHoy: cuadreEnviadoHoy ?? this.cuadreEnviadoHoy,
      );
}

class TurnoController extends Notifier<TurnoState> {
  TurnoRepository get _repo => ref.read(turnoRepositoryProvider);
  

  @override
  TurnoState build() => TurnoState(
        estaActivo: _repo.estaActivo,
        horaInicio: _repo.horaInicio,
        cuadreEnviadoHoy: _repo.cuadreEnviadoHoy,
      );

  void iniciarTurno() {
    _repo.iniciarTurno();
    state = TurnoState(estaActivo: true, horaInicio: _repo.horaInicio);
  }

  /// Agrega [cantidad] unidades de [producto] al cuadre activo.
  /// Si el producto ya existe, acumula la cantidad.
  /// Descuenta el stock inmediatamente.
  void agregarItem(Producto producto, int cantidad) {
    assert(cantidad > 0, 'La cantidad debe ser mayor a 0');

    // Record movimiento (dependiente sale) but do NOT modify stock until
    // the jefe aprueba el cuadre.
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      final now = DateTime.now();
      final mov = Movimiento(
        id: const Uuid().v4(),
        productoId: producto.id,
        productoNombre: producto.nombre,
        usuarioId: currentUser.id,
        usuarioNombre: currentUser.nombre,
        usuarioFotoUrl: currentUser.fotoUrl,
        tipo: MovimientoTipo.salida,
        cantidad: cantidad,
        nota: 'Venta de turno',
        fecha: now,
        synced: false,
        createdAt: now,
      );
      ref.read(movimientoRepositoryProvider).addMovimiento(mov);
    }

    final idx = state.items.indexWhere((i) => i.productoId == producto.id);
    final newItems = [...state.items];

    if (idx == -1) {
      newItems.add(
        CuadreItem(
          productoId: producto.id,
          productoNombre: producto.nombre,
          cantidad: cantidad,
          precioUnitario: producto.precio,
        ),
      );
    } else {
      final existing = newItems[idx];
      newItems[idx] = existing.copyWith(
        cantidad: existing.cantidad + cantidad,
      );
    }

    state = state.copyWith(items: newItems);
  }

  /// Actualiza la cantidad de un ítem ya existente.
  /// Ajusta el stock según la diferencia (sube o baja).
  /// Si [nuevaCantidad] <= 0, elimina el ítem y restaura el stock.
  void actualizarCantidadItem(String productoId, int nuevaCantidad) {
    final idx = state.items.indexWhere((i) => i.productoId == productoId);
    if (idx == -1) return;

    final existing = state.items[idx];
    final diferencia = nuevaCantidad - existing.cantidad;

    // Record movimiento for the delta (no stock change now)
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      final now = DateTime.now();
      if (diferencia != 0) {
        // Record as a sale adjustment. We avoid creating 'entrada' movements
        // for dependiente edits; negative quantities indicate a reduction
        // (correction) of previously registered ventas.
        final mov = Movimiento(
          id: const Uuid().v4(),
          productoId: productoId,
          productoNombre: existing.productoNombre,
          usuarioId: currentUser.id,
          usuarioNombre: currentUser.nombre,
          usuarioFotoUrl: currentUser.fotoUrl,
          tipo: MovimientoTipo.salida,
          cantidad: diferencia, // may be negative for reductions
          nota: diferencia > 0 ? 'Ajuste en turno (incremento)' : 'Ajuste en turno (reducción)',
          fecha: now,
          synced: false,
          createdAt: now,
        );
        ref.read(movimientoRepositoryProvider).addMovimiento(mov);
      }
    }

    final newItems = [...state.items];
    if (nuevaCantidad <= 0) {
      newItems.removeAt(idx);
    } else {
      newItems[idx] = existing.copyWith(cantidad: nuevaCantidad);
    }

    state = state.copyWith(items: newItems);
  }

  /// Elimina un ítem del cuadre y restaura su stock.
  void eliminarItem(String productoId) {
    final idx = state.items.indexWhere((i) => i.productoId == productoId);
    if (idx == -1) return;

    // Record a sale reduction movement (negative cantidad) for the removed
    // quantity so it reduces the pending ventas count but is not treated as
    // a physical entrada.
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      final now = DateTime.now();
      final mov = Movimiento(
        id: const Uuid().v4(),
        productoId: productoId,
        productoNombre: state.items[idx].productoNombre,
        usuarioId: currentUser.id,
        usuarioNombre: currentUser.nombre,
        usuarioFotoUrl: currentUser.fotoUrl,
        tipo: MovimientoTipo.salida,
        cantidad: -state.items[idx].cantidad,
        nota: 'Eliminado del turno (reducción)',
        fecha: now,
        synced: false,
        createdAt: now,
      );
      ref.read(movimientoRepositoryProvider).addMovimiento(mov);
    }

    final newItems = [...state.items]..removeAt(idx);
    state = state.copyWith(items: newItems);
  }

  /// Marca el turno como finalizado y limpia los ítems.
  void enviarCuadre() {
    _repo.enviarCuadre();
    state = state.copyWith(
      estaActivo: false,
      cuadreEnviadoHoy: true,
      items: [],
    );
  }
}

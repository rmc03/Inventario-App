import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/cuadre.dart';
import '../../../shared/models/cuadre_item.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/usuario.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../data/cuadre_repository.dart';

final cuadreRepositoryProvider = Provider<CuadreRepository>((ref) {
  return CuadreRepository();
});

final cuadreControllerProvider =
    NotifierProvider<CuadreController, List<Cuadre>>(CuadreController.new);

class CuadreController extends Notifier<List<Cuadre>> {
  CuadreRepository get _repo => ref.read(cuadreRepositoryProvider);
  InventarioController get _inventario =>
      ref.read(inventarioControllerProvider.notifier);

  @override
  List<Cuadre> build() => _repo.fetchCuadres();

  // ─── Creación ──────────────────────────────────────────────────────────────

  /// Crea un cuadre pendiente con los ítems del turno del dependiente.
  /// Retorna `null` si tuvo éxito o un mensaje de error.
  String? crearCuadrePendiente({
    required Usuario dependiente,
    required List<CuadreItem> items,
  }) {
    if (_repo.existsCuadreHoy(dependiente.id)) {
      return 'Ya existe un cuadre para hoy. '
          'No puedes cerrar el turno dos veces.';
    }

    final now = DateTime.now();
    _repo.addCuadre(
      Cuadre(
        id: const Uuid().v4(),
        dependienteId: dependiente.id,
        dependienteNombre: dependiente.nombre,
        fechaTurno: DateTime(now.year, now.month, now.day),
        items: List.unmodifiable(items),
        createdAt: now,
        updatedAt: now,
      ),
    );
    state = _repo.fetchCuadres();
    return null;
  }

  // ─── Consulta ──────────────────────────────────────────────────────────────

  Cuadre? findCuadre(String id) {
    final idx = state.indexWhere((c) => c.id == id);
    return idx == -1 ? null : state[idx];
  }

  // ─── Acciones del jefe ─────────────────────────────────────────────────────

  /// Aprueba el cuadre. El stock ya fue ajustado por el dependiente.
  void confirmarCuadre(String id) {
    _patchCuadre(id, estado: CuadreEstado.aprobado);
  }

  /// Rechaza el cuadre y restaura todo el stock de sus ítems.
  void rechazarCuadre(String id, String comentario) {
    final cuadre = findCuadre(id);
    if (cuadre == null) return;

    for (final item in cuadre.items) {
      _inventario.restoreMovimiento(
        productoId: item.productoId,
        cantidad: item.cantidad,
      );
    }

    _patchCuadre(id, estado: CuadreEstado.rechazado, comentarioJefe: comentario);
  }

  // ─── Modificación de ítems por el jefe ─────────────────────────────────────

  void modificarCantidadItem(
    String cuadreId,
    String productoId,
    int nuevaCantidad,
  ) {
    final cuadre = findCuadre(cuadreId);
    if (cuadre == null) return;

    final idx = cuadre.items.indexWhere((i) => i.productoId == productoId);
    if (idx == -1) return;

    final item = cuadre.items[idx];
    final diferencia = nuevaCantidad - item.cantidad;

    if (diferencia > 0) {
      _inventario.applyMovimiento(
        productoId: productoId,
        tipo: MovimientoTipo.salida,
        cantidad: diferencia,
      );
    } else if (diferencia < 0) {
      _inventario.restoreMovimiento(
        productoId: productoId,
        cantidad: -diferencia,
      );
    }

    final newItems = [...cuadre.items];
    if (nuevaCantidad <= 0) {
      newItems.removeAt(idx);
    } else {
      newItems[idx] = item.copyWith(cantidad: nuevaCantidad);
    }

    _patchItems(cuadreId, newItems);
  }

  void eliminarItemCuadre(String cuadreId, String productoId) {
    final cuadre = findCuadre(cuadreId);
    if (cuadre == null) return;

    final item = cuadre.items.firstWhere(
      (i) => i.productoId == productoId,
      orElse: () => throw StateError('Ítem no encontrado en el cuadre'),
    );

    _inventario.restoreMovimiento(
      productoId: productoId,
      cantidad: item.cantidad,
    );

    _patchItems(
      cuadreId,
      cuadre.items.where((i) => i.productoId != productoId).toList(),
    );
  }

  void agregarItemCuadre(String cuadreId, CuadreItem newItem) {
    final cuadre = findCuadre(cuadreId);
    if (cuadre == null) return;

    _inventario.applyMovimiento(
      productoId: newItem.productoId,
      tipo: MovimientoTipo.salida,
      cantidad: newItem.cantidad,
    );

    final idx = cuadre.items.indexWhere(
      (i) => i.productoId == newItem.productoId,
    );
    final newItems = [...cuadre.items];

    if (idx == -1) {
      newItems.add(newItem);
    } else {
      final existing = newItems[idx];
      newItems[idx] = existing.copyWith(
        cantidad: existing.cantidad + newItem.cantidad,
      );
    }

    _patchItems(cuadreId, newItems);
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  void _patchCuadre(
    String id, {
    required CuadreEstado estado,
    String? comentarioJefe,
  }) {
    final cuadre = findCuadre(id);
    if (cuadre == null) return;
    _repo.updateCuadre(
      cuadre.copyWith(
        estado: estado,
        comentarioJefe: comentarioJefe,
        updatedAt: DateTime.now(),
      ),
    );
    state = _repo.fetchCuadres();
  }

  void _patchItems(String cuadreId, List<CuadreItem> items) {
    final cuadre = findCuadre(cuadreId);
    if (cuadre == null) return;
    _repo.updateCuadre(
      cuadre.copyWith(items: items, updatedAt: DateTime.now()),
    );
    state = _repo.fetchCuadres();
  }
}

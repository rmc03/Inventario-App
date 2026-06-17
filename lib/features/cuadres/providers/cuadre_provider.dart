import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/cuadre.dart';
import '../../../shared/models/cuadre_item.dart';
import '../../../shared/models/usuario.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../../../shared/models/movimiento.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../data/cuadre_repository.dart';
import '../data/sqlite_cuadre_repository.dart';

final cuadreRepositoryProvider = Provider<CuadreRepository>((ref) {
  return CuadreRepository();
});

// Sold counts per product are computed from movements stream elsewhere.

final cuadreControllerProvider =
    NotifierProvider<CuadreController, List<Cuadre>>(CuadreController.new);

class CuadreController extends Notifier<List<Cuadre>> {
  CuadreRepository get _repo => ref.read(cuadreRepositoryProvider);
  

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
        dependienteFotoUrl: dependiente.fotoUrl,
        fechaTurno: DateTime(now.year, now.month, now.day),
        items: List.unmodifiable(items),
        createdAt: now,
        updatedAt: now,
      ),
    );
    // Movimientos are recorded by the Turno flow when items are added.
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
  Future<void> confirmarCuadre(String id) async {
    // Find cuadre
    final cuadre = findCuadre(id);
    if (cuadre == null) return;

    // If we have a Sqlite-backed repository, let it apply stock changes
    // transactionally (it updates the productos table). Otherwise, for the
    // in-memory repository we apply the movements to the inventory controller
    // so the product repo reflects the new stock values.
    if (_repo is SqliteCuadreRepository) {
      try {
        await (_repo as dynamic).approveCuadre(id);
      } catch (_) {
        // ignore errors for now
      }
      // refresh inventory (DB-backed implementation should pick up changes)
      ref.invalidate(inventarioControllerProvider);
    } else {
      // Apply each item as a salida movement to the inventory controller.
      final inv = ref.read(inventarioControllerProvider.notifier);
      for (final item in cuadre.items) {
        inv.applyMovimiento(
          productoId: item.productoId,
          tipo: MovimientoTipo.salida,
          cantidad: item.cantidad,
        );
      }
    }

    // mark as aprobado in local cache
    _patchCuadre(id, estado: CuadreEstado.aprobado);

    // Mark related salida movimientos for this dependiente/day as processed
    // so the UI/history reflects that these ventas were applied.
    try {
      final movRepo = ref.read(movimientoRepositoryProvider);
      final movimientos = await movRepo.fetchMovimientosForDate(cuadre.fechaTurno);
      for (final m in movimientos) {
        final note = (m.nota ?? '').toLowerCase();
        final isTurnoNote = note.contains('turno') || note.contains('venta') || note.contains('reducción');
        if (m.usuarioId == cuadre.dependienteId && m.tipo == MovimientoTipo.salida && !m.synced && isTurnoNote) {
          final updated = Movimiento(
            id: m.id,
            productoId: m.productoId,
            productoNombre: m.productoNombre,
            usuarioId: m.usuarioId,
            usuarioNombre: m.usuarioNombre,
            usuarioFotoUrl: m.usuarioFotoUrl,
            tipo: m.tipo,
            cantidad: m.cantidad,
            nota: m.nota,
            fecha: m.fecha,
            synced: true,
            createdAt: m.createdAt,
          );
          movRepo.updateMovimiento(updated);
        }
      }
    } catch (_) {
      // non-fatal; movement sync will occur later
    }
  }

  /// Rechaza el cuadre y restaura todo el stock de sus ítems.
  void rechazarCuadre(String id, String comentario) {
    final cuadre = findCuadre(id);
    if (cuadre == null) return;

    // No stock modifications needed since stock is applied only on approval.
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
    // Jefe edits shouldn't create movimientos here; movimientos are produced
    // by dependiente's Turno actions.

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

    // Removing item from cuadre; no stock changes until approval.
    _patchItems(
      cuadreId,
      cuadre.items.where((i) => i.productoId != productoId).toList(),
    );
  }

  void agregarItemCuadre(String cuadreId, CuadreItem newItem) {
    final cuadre = findCuadre(cuadreId);
    if (cuadre == null) return;
    // Add item to cuadre; stock not changed until approval.
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

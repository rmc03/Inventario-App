import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/venta.dart';

import '../../../shared/models/cuadre.dart';
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

  /// Crea un cuadre pendiente con las ventas del turno del dependiente.
  /// Retorna `null` si tuvo éxito o un mensaje de error.
  String? crearCuadrePendiente({
    required Usuario dependiente,
    required List<Venta> ventas,
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
        ventas: List.unmodifiable(ventas),
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

  /// Aprueba el cuadre. El stock ya fue ajustado por el dependiente durante las ventas.
  Future<void> confirmarCuadre(String id) async {
    final cuadre = findCuadre(id);
    if (cuadre == null) return;

    if (_repo is SqliteCuadreRepository) {
      try {
        await (_repo as dynamic).approveCuadre(id);
      } catch (_) {}
    }

    // mark as aprobado in local cache
    _patchCuadre(id, estado: CuadreEstado.aprobado);

    // Mark related salida movimientos for this dependiente/day as processed
    try {
      final movRepo = ref.read(movimientoRepositoryProvider);
      final movimientos = await movRepo.fetchMovimientosForDate(cuadre.fechaTurno);
      for (final m in movimientos) {
        final note = (m.nota ?? '').toLowerCase();
        final isTurnoNote = note.contains('venta pos');
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
    } catch (_) {}
  }

  /// Rechaza el cuadre y restaura todo el stock de las ventas.
  void rechazarCuadre(String id, String comentario) {
    final cuadre = findCuadre(id);
    if (cuadre == null) return;

    // Restaurar el stock de cada venta del cuadre
    final inv = ref.read(inventarioControllerProvider.notifier);
    final movRepo = ref.read(movimientoRepositoryProvider);

    for (final venta in cuadre.ventas) {
      for (final item in venta.items) {
        // Registrar movimiento de entrada compensatorio
        movRepo.addMovimiento(
          Movimiento(
            id: const Uuid().v4(),
            productoId: item.productoId,
            productoNombre: item.productoNombre,
            usuarioId: cuadre.dependienteId,
            usuarioNombre: cuadre.dependienteNombre,
            usuarioFotoUrl: cuadre.dependienteFotoUrl,
            tipo: MovimientoTipo.entrada,
            cantidad: item.cantidad, // La entrada es positiva
            fecha: DateTime.now(),
            nota: 'Reversión Venta POS #${venta.id.substring(0, 8)} (Cuadre rechazado)',
            createdAt: DateTime.now(),
          ),
        );

        // Restaurar en el inventario
        inv.applyMovimiento(
          productoId: item.productoId,
          tipo: MovimientoTipo.entrada,
          cantidad: item.cantidad,
        );
      }
    }

    _patchCuadre(id, estado: CuadreEstado.rechazado, comentarioJefe: comentario);
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


}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/local_db/local_database.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/usuario.dart';
import '../data/sqlite_movimiento_repository.dart';

final movimientoRepositoryProvider = Provider<SqliteMovimientoRepository>((ref) {
  // Use the local sqlite repository by default.
  return SqliteMovimientoRepository(LocalDatabase.instance);
});

// NOTE: current cuadre sales are computed from `cuadres` state (see cuadre_provider)
final currentCuadreSalesProvider = StreamProvider<Map<String, int>>((ref) {
  final repo = ref.watch(movimientoRepositoryProvider);
  return repo.movimientosStream.map((list) {
    final counts = <String, int>{};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    for (final m in list) {
      if (m.tipo == MovimientoTipo.salida && m.fecha.isAfter(start.subtract(const Duration(seconds: 1)))) {
        counts[m.productoId] = (counts[m.productoId] ?? 0) + m.cantidad;
      }
    }
    return counts;
  });
});

final movimientoControllerProvider =
    NotifierProvider<MovimientoController, List<Movimiento>>(
      MovimientoController.new,
    );

class MovimientoController extends Notifier<List<Movimiento>> {
  SqliteMovimientoRepository get _repository =>
      ref.read(movimientoRepositoryProvider);

  @override
  List<Movimiento> build() {
    // Ensure repository loaded and keep controller in sync with repository
    unawaited(_repository.ensureLoaded());

    // Subscribe to repository stream so external writes update this state
    final sub = _repository.movimientosStream.listen((list) {
      if (!ref.mounted) return;
      state = list;
    });
    ref.onDispose(() => sub.cancel());

    return _repository.fetchMovimientos();
  }

  void registrarMovimiento({
    required Producto producto,
    required Usuario usuario,
    required MovimientoTipo tipo,
    required int cantidad,
    String? nota,
  }) {
    final now = DateTime.now();
    final movimiento = Movimiento(
      id: const Uuid().v4(),
      productoId: producto.id,
      productoNombre: producto.nombre,
      usuarioId: usuario.id,
      usuarioNombre: usuario.nombre,
      usuarioFotoUrl: usuario.fotoUrl,
      tipo: tipo,
      cantidad: cantidad,
      nota: nota == null || nota.trim().isEmpty ? null : nota.trim(),
      fecha: now,
      synced: false,
      createdAt: now,
    );

    _repository.addMovimiento(movimiento);
    state = _repository.fetchMovimientos();
  }
}

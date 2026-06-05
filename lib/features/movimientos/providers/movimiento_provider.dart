import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/usuario.dart';
import '../data/movimiento_repository.dart';

final movimientoRepositoryProvider = Provider<MovimientoRepository>((ref) {
  return MovimientoRepository();
});

final movimientoControllerProvider =
    NotifierProvider<MovimientoController, List<Movimiento>>(
      MovimientoController.new,
    );

class MovimientoController extends Notifier<List<Movimiento>> {
  MovimientoRepository get _repository =>
      ref.read(movimientoRepositoryProvider);

  @override
  List<Movimiento> build() {
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

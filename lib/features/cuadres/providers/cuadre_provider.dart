import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/cuadre.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/usuario.dart';
import '../data/cuadre_repository.dart';

final cuadreRepositoryProvider = Provider<CuadreRepository>((ref) {
  return CuadreRepository();
});

final cuadreControllerProvider =
    NotifierProvider<CuadreController, List<Cuadre>>(CuadreController.new);

class CuadreController extends Notifier<List<Cuadre>> {
  CuadreRepository get _repository => ref.read(cuadreRepositoryProvider);

  @override
  List<Cuadre> build() {
    return _repository.fetchCuadres();
  }

  void crearCuadrePendiente({
    required Usuario dependiente,
    required List<Movimiento> movimientos,
  }) {
    final now = DateTime.now();
    final entradas = movimientos
        .where((movimiento) => movimiento.tipo == MovimientoTipo.entrada)
        .fold(0, (total, movimiento) => total + movimiento.cantidad);
    final salidas = movimientos
        .where((movimiento) => movimiento.tipo == MovimientoTipo.salida)
        .fold(0, (total, movimiento) => total + movimiento.cantidad);

    _repository.addCuadre(
      Cuadre(
        id: const Uuid().v4(),
        dependienteId: dependiente.id,
        dependienteNombre: dependiente.nombre,
        fechaTurno: DateTime(now.year, now.month, now.day),
        totalEntradas: entradas,
        totalSalidas: salidas,
        createdAt: now,
        updatedAt: now,
      ),
    );
    state = _repository.fetchCuadres();
  }

  Cuadre? findCuadre(String id) {
    final index = state.indexWhere((cuadre) => cuadre.id == id);
    if (index == -1) {
      return null;
    }
    return state[index];
  }

  void actualizarEstado({
    required String id,
    required CuadreEstado estado,
    String? comentarioJefe,
  }) {
    final cuadre = findCuadre(id);
    if (cuadre == null) {
      return;
    }

    _repository.updateCuadre(
      cuadre.copyWith(
        estado: estado,
        comentarioJefe: comentarioJefe,
        updatedAt: DateTime.now(),
      ),
    );
    state = _repository.fetchCuadres();
  }
}

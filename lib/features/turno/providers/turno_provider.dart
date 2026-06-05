import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/movimiento.dart';
import '../../auth/providers/auth_provider.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../data/turno_repository.dart';

final turnoRepositoryProvider = Provider<TurnoRepository>((ref) {
  return TurnoRepository();
});

final turnoControllerProvider = NotifierProvider<TurnoController, TurnoState>(
  TurnoController.new,
);

final movimientosTurnoProvider = Provider<List<Movimiento>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  final movimientos = ref.watch(movimientoControllerProvider);
  if (user == null) {
    return const [];
  }

  final now = DateTime.now();
  return movimientos.where((movimiento) {
    return movimiento.usuarioId == user.id &&
        movimiento.fecha.year == now.year &&
        movimiento.fecha.month == now.month &&
        movimiento.fecha.day == now.day;
  }).toList();
});

class TurnoState {
  const TurnoState({required this.cerradoHoy});

  final bool cerradoHoy;
}

class TurnoController extends Notifier<TurnoState> {
  TurnoRepository get _repository => ref.read(turnoRepositoryProvider);

  @override
  TurnoState build() {
    return TurnoState(cerradoHoy: _repository.cerradoHoy);
  }

  void cerrarTurno() {
    _repository.cerrarTurno();
    state = TurnoState(cerradoHoy: _repository.cerradoHoy);
  }
}

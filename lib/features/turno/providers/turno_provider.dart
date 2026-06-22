import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/turno_repository.dart';

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
    this.cuadreEnviadoHoy = false,
    this.permitirVentas = true,
  });

  final bool estaActivo;
  final DateTime? horaInicio;
  final bool cuadreEnviadoHoy;
  final bool permitirVentas;

  TurnoState copyWith({
    bool? estaActivo,
    DateTime? horaInicio,
    bool? cuadreEnviadoHoy,
    bool? permitirVentas,
  }) =>
      TurnoState(
        estaActivo: estaActivo ?? this.estaActivo,
        horaInicio: horaInicio ?? this.horaInicio,
        cuadreEnviadoHoy: cuadreEnviadoHoy ?? this.cuadreEnviadoHoy,
        permitirVentas: permitirVentas ?? this.permitirVentas,
      );
}

class TurnoController extends Notifier<TurnoState> {
  TurnoRepository get _repo => ref.read(turnoRepositoryProvider);
  
  @override
  TurnoState build() => TurnoState(
        estaActivo: _repo.estaActivo,
        horaInicio: _repo.horaInicio,
        cuadreEnviadoHoy: _repo.cuadreEnviadoHoy,
        permitirVentas: _repo.estaActivo && !_repo.cuadreEnviadoHoy,
      );

  void iniciarTurno() {
    _repo.iniciarTurno();
    state = TurnoState(
      estaActivo: true,
      horaInicio: _repo.horaInicio,
      permitirVentas: true,
    );
  }

  /// Marca el turno como finalizado.
  void enviarCuadre() {
    _repo.enviarCuadre();
    state = state.copyWith(
      estaActivo: false,
      cuadreEnviadoHoy: true,
      permitirVentas: false,
    );
  }
}


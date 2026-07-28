import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cuadre.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cuadres/providers/cuadre_provider.dart';
import '../../movimientos/providers/movimiento_provider.dart';
import '../../ventas/providers/venta_provider.dart';
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
  TurnoState build() {
    // Observar los cuadres para actualizar el estado cuando cambien
    ref.watch(cuadreControllerProvider);
    
    // Verificar si hay un cuadre pendiente del día
    final tieneCuadrePendiente = _tieneCuadrePendienteHoy();
    
    return TurnoState(
      estaActivo: _repo.estaActivo,
      horaInicio: _repo.horaInicio,
      cuadreEnviadoHoy: tieneCuadrePendiente,
      permitirVentas: _repo.estaActivo,
    );
  }

  /// Verifica si existe un cuadre pendiente para hoy del usuario actual
  bool _tieneCuadrePendienteHoy() {
    final usuario = ref.read(authControllerProvider).user;
    if (usuario == null) return false;

    final cuadres = ref.read(cuadreControllerProvider);
    final hoy = DateTime.now();
    
    return cuadres.any((c) =>
      c.dependienteId == usuario.id &&
      c.estado == CuadreEstado.pendiente &&
      _isSameDay(c.fechaTurno, hoy)
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? iniciarTurno() {
    try {
      // Verificar si hay un cuadre pendiente ANTES de limpiar las ventas
      final tieneCuadrePendiente = _tieneCuadrePendienteHoy();
      
      _repo.iniciarTurno();
      
      // Solo limpiar ventas si NO hay cuadre pendiente
      // (es un turno completamente nuevo, no una reapertura)
      if (!tieneCuadrePendiente) {
        ref.read(ventasDelTurnoProvider.notifier).clearVentas();
      }
      
      state = TurnoState(
        estaActivo: true,
        horaInicio: _repo.horaInicio,
        cuadreEnviadoHoy: tieneCuadrePendiente,
        permitirVentas: true,
      );
      
      // Registrar inicio de turno como movimiento solo si es turno nuevo
      if (!tieneCuadrePendiente) {
        final usuario = ref.read(authControllerProvider).user;
        if (usuario != null) {
          ref.read(movimientoControllerProvider.notifier).registrarInicioTurno(
            dependiente: usuario,
          );
        }
      }
      return null;
    } catch (e) {
      return 'Error al iniciar turno: ${e.toString()}';
    }
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

  /// Reabre el turno para permitir más ventas después de enviar el cuadre.
  /// El cuadre pendiente se actualizará automáticamente.
  void reabrirTurno() {
    _repo.reabrirTurno();
    
    final tieneCuadrePendiente = _tieneCuadrePendienteHoy();
    
    state = state.copyWith(
      estaActivo: true,
      cuadreEnviadoHoy: tieneCuadrePendiente,
      permitirVentas: true,
    );
  }
}


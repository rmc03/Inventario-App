class TurnoRepository {
  bool _cerradoHoy = false;

  bool get cerradoHoy => _cerradoHoy;

  void cerrarTurno() {
    _cerradoHoy = true;
  }

  void reabrirTurno() {
    _cerradoHoy = false;
  }
}

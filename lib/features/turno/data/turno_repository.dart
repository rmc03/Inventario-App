class TurnoRepository {
  bool _estaActivo = false;
  DateTime? _horaInicio;
  bool _cuadreEnviadoHoy = false;

  bool get estaActivo => _estaActivo;
  DateTime? get horaInicio => _horaInicio;
  bool get cuadreEnviadoHoy => _cuadreEnviadoHoy;

  void iniciarTurno() {
    _estaActivo = true;
    _horaInicio = DateTime.now();
    _cuadreEnviadoHoy = false;
  }

  void enviarCuadre() {
    _estaActivo = false;
    _cuadreEnviadoHoy = true;
  }

  void resetearDia() {
    _cuadreEnviadoHoy = false;
  }
}

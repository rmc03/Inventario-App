class TurnoRepository {
  bool _estaActivo = false;
  DateTime? _horaInicio;
  bool _cuadreEnviadoHoy = false;
  DateTime? _fechaCuadre; // Fecha en que se envió el cuadre

  bool get estaActivo {
    _verificarCambioDeDia();
    return _estaActivo;
  }

  DateTime? get horaInicio {
    _verificarCambioDeDia();
    return _horaInicio;
  }

  bool get cuadreEnviadoHoy {
    _verificarCambioDeDia();
    return _cuadreEnviadoHoy;
  }

  void iniciarTurno() {
    _estaActivo = true;
    _horaInicio = DateTime.now();
    _cuadreEnviadoHoy = false;
    _fechaCuadre = null;
  }

  void enviarCuadre() {
    _estaActivo = false;
    _cuadreEnviadoHoy = true;
    _fechaCuadre = DateTime.now();
  }

  void reabrirTurno() {
    _estaActivo = true;
    // Mantener _cuadreEnviadoHoy = true para indicar que hay un cuadre pendiente
    // pero permitir que siga vendiendo
  }

  void resetearDia() {
    _cuadreEnviadoHoy = false;
    _fechaCuadre = null;
  }

  /// Limpia las ventas al iniciar un nuevo día.
  /// Este método debe llamarse desde el provider cuando se detecta cambio de día.
  void limpiarVentas() {
    // Este método se llamará desde el TurnoController cuando sea necesario
  }

  /// Verifica si ha pasado un día desde que se envió el cuadre.
  /// Si es un nuevo día, resetea el estado automáticamente.
  /// 
  /// IMPORTANTE PARA PRODUCCIÓN:
  /// - Esta implementación usa memoria volátil (se resetea al cerrar la app)
  /// - En producción, debes persistir _fechaCuadre en SharedPreferences o base de datos
  /// - Considera zonas horarias si operas en múltiples regiones
  /// - El cambio de día ocurre a medianoche (00:00:00)
  void _verificarCambioDeDia() {
    if (_fechaCuadre == null || !_cuadreEnviadoHoy) {
      return;
    }

    final ahora = DateTime.now();
    final fechaCuadreSoloDia = DateTime(
      _fechaCuadre!.year,
      _fechaCuadre!.month,
      _fechaCuadre!.day,
    );
    final hoyDia = DateTime(ahora.year, ahora.month, ahora.day);

    // Si la fecha del cuadre es diferente al día de hoy, resetear
    if (fechaCuadreSoloDia.isBefore(hoyDia)) {
      resetearDia();
    }
  }
}

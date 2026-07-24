import '../../../shared/models/movimiento.dart';

enum TipoMovimientoFiltro { todos, entradas, salidas, ventas, inicioTurno, eliminados }

enum RangoFechaFiltro { hoy, semana, mes, personalizado }

class MovimientosFilterState {
  const MovimientosFilterState({
    this.tipo = TipoMovimientoFiltro.todos,
    this.rango = RangoFechaFiltro.hoy,
    this.fechaInicioCustom,
    this.fechaFinCustom,
    this.query = '',
  });

  final TipoMovimientoFiltro tipo;
  final RangoFechaFiltro rango;
  final DateTime? fechaInicioCustom;
  final DateTime? fechaFinCustom;
  final String query;

  MovimientosFilterState copyWith({
    TipoMovimientoFiltro? tipo,
    RangoFechaFiltro? rango,
    DateTime? fechaInicioCustom,
    bool clearFechaInicioCustom = false,
    DateTime? fechaFinCustom,
    bool clearFechaFinCustom = false,
    String? query,
  }) {
    return MovimientosFilterState(
      tipo: tipo ?? this.tipo,
      rango: rango ?? this.rango,
      fechaInicioCustom: clearFechaInicioCustom
          ? null
          : (fechaInicioCustom ?? this.fechaInicioCustom),
      fechaFinCustom: clearFechaFinCustom
          ? null
          : (fechaFinCustom ?? this.fechaFinCustom),
      query: query ?? this.query,
    );
  }

  /// Inicio del rango (inclusive), en hora local del dispositivo.
  DateTime get fechaInicio {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (rango) {
      case RangoFechaFiltro.hoy:
        return startOfToday;
      case RangoFechaFiltro.semana:
        // Últimos 7 días incluyendo hoy.
        return startOfToday.subtract(const Duration(days: 6));
      case RangoFechaFiltro.mes:
        // Últimos 30 días incluyendo hoy.
        return startOfToday.subtract(const Duration(days: 29));
      case RangoFechaFiltro.personalizado:
        final c = fechaInicioCustom;
        return c == null
            ? startOfToday
            : DateTime(c.year, c.month, c.day);
    }
  }

  /// Fin del rango (exclusive). Para "hoy" es medianoche de mañana; para
  /// "personalizado" se suma un día a la fecha fin elegida para incluirla
  /// completa (inclusive en ambos extremos a nivel de día).
  DateTime get fechaFin {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    switch (rango) {
      case RangoFechaFiltro.hoy:
      case RangoFechaFiltro.semana:
      case RangoFechaFiltro.mes:
        return startOfTomorrow;
      case RangoFechaFiltro.personalizado:
        final c = fechaFinCustom;
        return c == null
            ? startOfTomorrow
            : DateTime(c.year, c.month, c.day)
                .add(const Duration(days: 1));
    }
  }
}

/// Aplica los filtros compartidos (tipo, fecha, búsqueda) sobre una lista de
/// movimientos. Función pura reutilizable tanto por la implementación SQLite
/// como por el provider derivado reactivo (y más adelante por Supabase).
List<Movimiento> filtrarMovimientos(
  List<Movimiento> source,
  MovimientosFilterState filtro,
) {
  final inicio = filtro.fechaInicio;
  final fin = filtro.fechaFin;
  final q = filtro.query.trim().toLowerCase();

  return source.where((m) {
    final tipoOk = filtro.tipo == TipoMovimientoFiltro.todos ||
        (filtro.tipo == TipoMovimientoFiltro.entradas &&
            m.tipo == MovimientoTipo.entrada) ||
        (filtro.tipo == TipoMovimientoFiltro.salidas &&
            m.tipo == MovimientoTipo.salida) ||
        (filtro.tipo == TipoMovimientoFiltro.ventas &&
            m.tipo == MovimientoTipo.venta) ||
        (filtro.tipo == TipoMovimientoFiltro.inicioTurno &&
            m.tipo == MovimientoTipo.inicioTurno) ||
        (filtro.tipo == TipoMovimientoFiltro.eliminados &&
            m.tipo == MovimientoTipo.productoEliminado);
    if (!tipoOk) return false;

    // Fecha: [inicio, fin)
    if (m.fecha.isBefore(inicio)) return false;
    if (!m.fecha.isBefore(fin)) return false;

    if (q.isNotEmpty) {
      final producto = m.productoNombre.toLowerCase();
      final usuario = m.usuarioNombre.toLowerCase();
      if (!producto.contains(q) && !usuario.contains(q)) return false;
    }
    return true;
  }).toList();
}

/// Única fuente de datos de movimientos. La implementación activa es
/// SQLite (local); más adelante se podrá agregar una implementación
/// Supabase sin tocar el provider ni la UI.
abstract class MovimientoRepository {
  Future<void> ensureLoaded();
  Stream<List<Movimiento>> get movimientosStream;
  List<Movimiento> fetchMovimientos();
  void addMovimiento(Movimiento movimiento);
  void updateMovimiento(Movimiento movimiento);
  Future<List<Movimiento>> getMovimientos(MovimientosFilterState filtro);
  Future<List<Movimiento>> fetchMovimientosForDate(DateTime day);
}

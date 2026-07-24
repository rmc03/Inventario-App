import 'dart:async';

import '../../../core/local_db/local_database.dart';
import '../../../shared/models/movimiento.dart';
import 'movimiento_repository.dart';

class SqliteMovimientoRepository implements MovimientoRepository {
  SqliteMovimientoRepository(this._db);

  final LocalDatabase _db;

  List<Movimiento> _cache = [];
  final StreamController<List<Movimiento>> _controller = StreamController<List<Movimiento>>.broadcast();

  @override
  Stream<List<Movimiento>> get movimientosStream => _controller.stream;

  @override
  Future<void> ensureLoaded() async {
    final db = await _db.database;
    final rows = await db.query('movimientos', orderBy: 'fecha DESC');
    _cache = rows.map((r) => Movimiento.fromLocalMap(r)).toList();
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  List<Movimiento> fetchMovimientos() {
    return List.unmodifiable(_cache);
  }

  @override
  void updateMovimiento(Movimiento movimiento) {
    final idx = _cache.indexWhere((m) => m.id == movimiento.id);
    if (idx != -1) _cache[idx] = movimiento;
    _db.database.then((d) async {
      await d.update('movimientos', movimiento.toLocalMap(),
          where: 'id = ?', whereArgs: [movimiento.id]);
      _controller.add(List.unmodifiable(_cache));
    });
  }

  @override
  void addMovimiento(Movimiento movimiento) {
    _cache.insert(0, movimiento);
    _db.database.then((d) async {
      await d.insert('movimientos', movimiento.toLocalMap());
      _controller.add(List.unmodifiable(_cache));
    });
  }

  void deleteMovimiento(String id) {
    _cache.removeWhere((m) => m.id == id);
    _db.database.then((d) async {
      await d.delete('movimientos', where: 'id = ?', whereArgs: [id]);
      _controller.add(List.unmodifiable(_cache));
    });
  }

  @override
  Future<List<Movimiento>> fetchMovimientosForDate(DateTime day) async {
    final db = await _db.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'movimientos',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map((r) => Movimiento.fromLocalMap(r)).toList();
  }

  @override
  Future<List<Movimiento>> getMovimientos(MovimientosFilterState filtro) async {
    // El volumen de datos locales es bajo: filtramos en memoria. La
    // implementación Supabase hará la query del lado del servidor.
    return filtrarMovimientos(fetchMovimientos(), filtro);
  }

  void dispose() {
    try {
      _controller.close();
    } catch (_) {}
  }
}

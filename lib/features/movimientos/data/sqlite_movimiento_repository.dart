import 'dart:async';

import '../../../core/local_db/local_database.dart';
import '../../../shared/models/movimiento.dart';

class SqliteMovimientoRepository {
  SqliteMovimientoRepository(this._db);

  final LocalDatabase _db;

  List<Movimiento> _cache = [];
  final StreamController<List<Movimiento>> _controller = StreamController<List<Movimiento>>.broadcast();

  Stream<List<Movimiento>> get movimientosStream => _controller.stream;

  Future<void> ensureLoaded() async {
    final db = await _db.database;
    final rows = await db.query('movimientos', orderBy: 'fecha DESC');
    _cache = rows.map((r) => Movimiento.fromLocalMap(r)).toList();
    _controller.add(List.unmodifiable(_cache));
  }

  List<Movimiento> fetchMovimientos() {
    return List.unmodifiable(_cache);
  }

  void addMovimiento(Movimiento movimiento) {
    _cache.insert(0, movimiento);
    _db.database.then((d) async {
      final map = movimiento.toLocalMap()
        ..['synced'] = movimiento.synced ? 1 : 0;
      await d.insert('movimientos', map);
      _controller.add(List.unmodifiable(_cache));
    });
  }

  void updateMovimiento(Movimiento movimiento) {
    final idx = _cache.indexWhere((m) => m.id == movimiento.id);
    if (idx != -1) _cache[idx] = movimiento;
    _db.database.then((d) async {
      await d.update('movimientos', movimiento.toLocalMap(), where: 'id = ?', whereArgs: [movimiento.id]);
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

  void dispose() {
    try {
      _controller.close();
    } catch (_) {}
  }
}

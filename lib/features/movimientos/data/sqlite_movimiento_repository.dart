import '../../../core/local_db/local_database.dart';
import '../../../shared/models/movimiento.dart';

class SqliteMovimientoRepository {
  SqliteMovimientoRepository(this._db);

  final LocalDatabase _db;

  List<Movimiento> _cache = [];

  Future<void> ensureLoaded() async {
    final db = await _db.database;
    final rows = await db.query('movimientos', orderBy: 'fecha DESC');
    _cache = rows.map((r) => Movimiento.fromLocalMap(r)).toList();
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
    });
  }
}

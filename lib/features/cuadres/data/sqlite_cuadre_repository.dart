import 'dart:convert';

import '../../../core/local_db/local_database.dart';
import '../../../shared/models/cuadre.dart';
import '../../../shared/models/cuadre_item.dart';

class SqliteCuadreRepository {
  SqliteCuadreRepository(this._db);

  final LocalDatabase _db;

  List<Cuadre> _cache = [];

  Future<void> ensureLoaded() async {
    final db = await _db.database;
    final rows = await db.query('cuadres', orderBy: 'fecha_turno DESC');
    _cache = rows.map((r) => _fromRow(r)).toList();
  }

  List<Cuadre> fetchCuadres() {
    return List.unmodifiable(_cache);
  }

  void addCuadre(Cuadre cuadre) {
    _cache.insert(0, cuadre);
    _db.database.then((d) async {
      await d.insert('cuadres', _toRow(cuadre));
    });
  }

  void updateCuadre(Cuadre cuadre) {
    final index = _cache.indexWhere((c) => c.id == cuadre.id);
    if (index != -1) {
      _cache[index] = cuadre;
    }
    _db.database.then((d) async {
      await d.update(
        'cuadres',
        _toRow(cuadre),
        where: 'id = ?',
        whereArgs: [cuadre.id],
      );
    });
  }

  bool existsCuadreHoy(String dependienteId) {
    final hoy = DateTime.now();
    return _cache.any(
      (c) =>
          c.dependienteId == dependienteId &&
          c.fechaTurno.year == hoy.year &&
          c.fechaTurno.month == hoy.month &&
          c.fechaTurno.day == hoy.day,
    );
  }

  Map<String, dynamic> _toRow(Cuadre cuadre) {
    return {
      'id': cuadre.id,
      'dependiente_id': cuadre.dependienteId,
      'dependiente_nombre': cuadre.dependienteNombre,
      'fecha_turno': cuadre.fechaTurno.toIso8601String(),
      'total_entradas': 0,
      'total_salidas': cuadre.totalSalidas,
      'estado': cuadre.estado.name,
      'comentario_jefe': cuadre.comentarioJefe,
      'items_json': jsonEncode(cuadre.items.map((i) => i.toJson()).toList()),
      'synced': cuadre.synced ? 1 : 0,
      'created_at': cuadre.createdAt.toIso8601String(),
      'updated_at': cuadre.updatedAt.toIso8601String(),
    };
  }

  Cuadre _fromRow(Map<String, dynamic> row) {
    final itemsJson = row['items_json'] as String?;
    final items = itemsJson != null
        ? (jsonDecode(itemsJson) as List<dynamic>)
            .map((e) => CuadreItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CuadreItem>[];

    return Cuadre(
      id: row['id'] as String,
      dependienteId: row['dependiente_id'] as String,
      dependienteNombre:
          (row['dependiente_nombre'] as String?) ?? 'Dependiente',
      fechaTurno: DateTime.parse(row['fecha_turno'] as String),
      items: items,
      estado: CuadreEstado.fromValue(
        (row['estado'] as String?) ?? 'pendiente',
      ),
      comentarioJefe: row['comentario_jefe'] as String?,
      synced: (row['synced'] as int?) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

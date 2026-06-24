import 'package:sqflite/sqflite.dart';

import '../../../core/local_db/local_database.dart';
import '../../../shared/models/usuario.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> fetchUsuarios({bool soloActivos = true});
  Future<Usuario?> findUsuario(String id);
  Future<void> upsertUsuario(Usuario usuario);
  Future<void> deleteUsuario(String id);
  Future<bool> existsEmail(String email, {String? excludeId});
}

class SqliteUsuarioRepository implements UsuarioRepository {
  @override
  Future<List<Usuario>> fetchUsuarios({bool soloActivos = true}) async {
    final db = await LocalDatabase.instance.database;
    final rows = soloActivos
        ? await db.query('usuarios', where: 'activo = ?', whereArgs: [1])
        : await db.query('usuarios');
    return rows.map(Usuario.fromLocalMap).toList();
  }

  @override
  Future<Usuario?> findUsuario(String id) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Usuario.fromLocalMap(rows.first);
  }

  @override
  Future<void> upsertUsuario(Usuario usuario) async {
    final db = await LocalDatabase.instance.database;
    final map = usuario.toLocalMap();
    map['activo'] = usuario.activo ? 1 : 0;
    await db.insert('usuarios', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteUsuario(String id) async {
    final db = await LocalDatabase.instance.database;
    await db.update('usuarios', {'activo': 0}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> existsEmail(String email, {String? excludeId}) async {
    final db = await LocalDatabase.instance.database;
    final where = excludeId != null
        ? 'email = ? AND id != ?'
        : 'email = ?';
    final whereArgs = excludeId != null
        ? [email, excludeId]
        : [email];
    final rows = await db.query('usuarios', where: where, whereArgs: whereArgs);
    return rows.isNotEmpty;
  }
}

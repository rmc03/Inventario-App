import '../../../shared/models/usuario.dart';
import '../../../core/local_db/local_database.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  Future<Usuario> signIn({
    required String email,
    required String password,
    UserRole? preferredRole,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final role =
        preferredRole ??
        (normalizedEmail.contains('admin')
            ? UserRole.admin
            : UserRole.dependiente);
    final id = role == UserRole.admin
        ? '00000000-0000-4000-9000-000000000001'
        : '00000000-0000-4000-9000-000000000002';

    final db = await LocalDatabase.instance.database;
    final rows = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      return Usuario.fromLocalMap(rows.first);
    }

    final user = Usuario(
      id: id,
      email: normalizedEmail.isEmpty ? _demoEmailFor(role) : normalizedEmail,
      nombre: role == UserRole.admin ? 'Ruslan Jefe' : 'Dependiente Demo',
      rol: role,
      createdAt: DateTime.now(),
    );

    await db.insert('usuarios', user.toLocalMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return user;
  }

  String _demoEmailFor(UserRole role) {
    return switch (role) {
      UserRole.admin => 'admin@inventario.local',
      UserRole.dependiente => 'dependiente@inventario.local',
    };
  }
}

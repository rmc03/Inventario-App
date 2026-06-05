import '../../../shared/models/usuario.dart';

class AuthRepository {
  Usuario signIn({
    required String email,
    required String password,
    UserRole? preferredRole,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final role =
        preferredRole ??
        (normalizedEmail.contains('admin')
            ? UserRole.admin
            : UserRole.dependiente);

    return Usuario(
      id: role == UserRole.admin
          ? '00000000-0000-4000-9000-000000000001'
          : '00000000-0000-4000-9000-000000000002',
      email: normalizedEmail.isEmpty ? _demoEmailFor(role) : normalizedEmail,
      nombre: role == UserRole.admin ? 'Ruslan Jefe' : 'Dependiente Demo',
      rol: role,
      createdAt: DateTime.now(),
    );
  }

  String _demoEmailFor(UserRole role) {
    return switch (role) {
      UserRole.admin => 'admin@inventario.local',
      UserRole.dependiente => 'dependiente@inventario.local',
    };
  }
}

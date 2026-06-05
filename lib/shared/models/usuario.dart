enum UserRole {
  admin,
  dependiente;

  String get label {
    return switch (this) {
      UserRole.admin => 'Admin',
      UserRole.dependiente => 'Dependiente',
    };
  }

  String get homePath {
    return switch (this) {
      UserRole.admin => '/admin/inventario',
      UserRole.dependiente => '/dependiente/inventario',
    };
  }

  static UserRole fromValue(String value) {
    return switch (value) {
      'admin' => UserRole.admin,
      'dependiente' => UserRole.dependiente,
      _ => UserRole.dependiente,
    };
  }
}

class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    this.activo = true,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String nombre;
  final UserRole rol;
  final bool activo;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'rol': rol.name,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: UserRole.fromValue(json['rol'] as String),
      activo: (json['activo'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() => toJson();

  factory Usuario.fromLocalMap(Map<String, dynamic> map) {
    return Usuario.fromJson(map);
  }
}

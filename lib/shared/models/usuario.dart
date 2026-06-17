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
    this.fotoUrl,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String nombre;
  final UserRole rol;
  final bool activo;
  final String? fotoUrl;
  final DateTime createdAt;

  Usuario copyWith({
    String? id,
    String? email,
    String? nombre,
    UserRole? rol,
    bool? activo,
    String? fotoUrl,
    DateTime? createdAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'rol': rol.name,
      'activo': activo,
      'foto_url': fotoUrl,
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
      fotoUrl: json['foto_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() => toJson();

  factory Usuario.fromLocalMap(Map<String, dynamic> map) {
    final createdAt = map['created_at'] as String?;
    return Usuario(
      id: map['id'] as String,
      email: map['email'] as String,
      nombre: map['nombre'] as String,
      rol: UserRole.fromValue(map['rol'] as String),
      activo: (map['activo'] as int?) == 1 || (map['activo'] as bool?) == true,
      fotoUrl: map['foto_url'] as String?,
      createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
    );
  }
}

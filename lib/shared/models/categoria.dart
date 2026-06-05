class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.createdAt,
  });

  final String id;
  final String nombre;
  final DateTime createdAt;

  Categoria copyWith({String? id, String? nombre, DateTime? createdAt}) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() => toJson();

  factory Categoria.fromLocalMap(Map<String, dynamic> map) {
    return Categoria.fromJson(map);
  }
}

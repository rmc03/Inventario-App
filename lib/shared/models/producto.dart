class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
    this.categoriaNombre,
    required this.precio,
    required this.stockActual,
    required this.stockMinimo,
    this.codigoRef,
    this.fotoUrl,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String categoriaId;
  final String? categoriaNombre;
  final double precio;
  final int stockActual;
  final int stockMinimo;
  final String? codigoRef;
  final String? fotoUrl;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get tieneStockBajo => stockActual <= stockMinimo;
  double get valorTotal => precio * stockActual;

  Producto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? categoriaId,
    String? categoriaNombre,
    double? precio,
    int? stockActual,
    int? stockMinimo,
    String? codigoRef,
    String? fotoUrl,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      precio: precio ?? this.precio,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      codigoRef: codigoRef ?? this.codigoRef,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'precio': precio,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'codigo_ref': codigoRef,
      'foto_url': fotoUrl,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      categoriaId: json['categoria_id'] as String,
      categoriaNombre: json['categoria_nombre'] as String?,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      stockActual: (json['stock_actual'] as num?)?.toInt() ?? 0,
      stockMinimo: (json['stock_minimo'] as num?)?.toInt() ?? 0,
      codigoRef: json['codigo_ref'] as String?,
      fotoUrl: json['foto_url'] as String?,
      activo: (json['activo'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {...toJson(), 'categoria_nombre': categoriaNombre};
  }

  factory Producto.fromLocalMap(Map<String, dynamic> map) {
    return Producto.fromJson(map);
  }
}

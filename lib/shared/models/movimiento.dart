enum MovimientoTipo {
  entrada,
  salida;

  String get label {
    return switch (this) {
      MovimientoTipo.entrada => 'Entrada',
      MovimientoTipo.salida => 'Salida',
    };
  }

  static MovimientoTipo fromValue(String value) {
    return switch (value) {
      'entrada' => MovimientoTipo.entrada,
      'salida' => MovimientoTipo.salida,
      _ => MovimientoTipo.salida,
    };
  }
}

class Movimiento {
  const Movimiento({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.tipo,
    required this.cantidad,
    this.nota,
    required this.fecha,
    this.synced = false,
    required this.createdAt,
  });

  final String id;
  final String productoId;
  final String productoNombre;
  final String usuarioId;
  final String usuarioNombre;
  final MovimientoTipo tipo;
  final int cantidad;
  final String? nota;
  final DateTime fecha;
  final bool synced;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'nota': nota,
      'fecha': fecha.toIso8601String(),
      'synced': synced,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id: json['id'] as String,
      productoId: json['producto_id'] as String,
      productoNombre: (json['producto_nombre'] as String?) ?? 'Producto',
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: (json['usuario_nombre'] as String?) ?? 'Usuario',
      tipo: MovimientoTipo.fromValue(json['tipo'] as String),
      cantidad: (json['cantidad'] as num).toInt(),
      nota: json['nota'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      synced: (json['synced'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() => toJson();

  factory Movimiento.fromLocalMap(Map<String, dynamic> map) {
    return Movimiento.fromJson(map);
  }
}

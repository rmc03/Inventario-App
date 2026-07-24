import 'dart:convert';

enum MovimientoTipo {
  entrada,
  salida,
  inicioTurno,
  venta,
  productoEliminado;

  String get label {
    return switch (this) {
      MovimientoTipo.entrada => 'Entrada',
      MovimientoTipo.salida => 'Salida',
      MovimientoTipo.inicioTurno => 'Inicio de Turno',
      MovimientoTipo.venta => 'Venta',
      MovimientoTipo.productoEliminado => 'Producto Eliminado',
    };
  }

  static MovimientoTipo fromValue(String value) {
    return switch (value) {
      'entrada' => MovimientoTipo.entrada,
      'salida' => MovimientoTipo.salida,
      'inicioTurno' => MovimientoTipo.inicioTurno,
      'venta' => MovimientoTipo.venta,
      'productoEliminado' => MovimientoTipo.productoEliminado,
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
    this.usuarioFotoUrl,
    required this.tipo,
    required this.cantidad,
    this.nota,
    required this.fecha,
    this.synced = false,
    required this.createdAt,
    this.ventaId,
    this.precioUnitario,
    this.totalVenta,
    this.productosVendidos,
  });

  final String id;
  final String productoId;
  final String productoNombre;
  final String usuarioId;
  final String usuarioNombre;
  final String? usuarioFotoUrl;
  final MovimientoTipo tipo;
  final int cantidad;
  final String? nota;
  final DateTime fecha;
  final bool synced;
  final DateTime createdAt;
  final String? ventaId;
  final double? precioUnitario;
  final double? totalVenta;
  final List<String>? productosVendidos; // Lista de nombres para vista rápida

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'usuario_foto_url': usuarioFotoUrl,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'nota': nota,
      'fecha': fecha.toIso8601String(),
      'synced': synced,
      'created_at': createdAt.toIso8601String(),
      'venta_id': ventaId,
      'precio_unitario': precioUnitario,
      'total_venta': totalVenta,
      'productos_vendidos': productosVendidos,
    };
  }

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    final rawProductos = json['productos_vendidos'];
    return Movimiento(
      id: json['id'] as String,
      productoId: json['producto_id'] as String,
      productoNombre: (json['producto_nombre'] as String?) ?? 'Producto',
      usuarioId: json['usuario_id'] as String,
      usuarioNombre: (json['usuario_nombre'] as String?) ?? 'Usuario',
      usuarioFotoUrl: json['usuario_foto_url'] as String?,
      tipo: MovimientoTipo.fromValue(json['tipo'] as String),
      cantidad: (json['cantidad'] as num).toInt(),
      nota: json['nota'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      synced: (json['synced'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      ventaId: json['venta_id'] as String?,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble(),
      totalVenta: (json['total_venta'] as num?)?.toDouble(),
      productosVendidos: rawProductos != null 
        ? (rawProductos as List<dynamic>).map((e) => e as String).toList()
        : null,
    );
  }

  Map<String, dynamic> toLocalMap() {
    final map = toJson();
    // Para SQLite, convertir la lista a JSON string
    if (productosVendidos != null) {
      map['productos_vendidos'] = jsonEncode(productosVendidos);
    }
    // SQLite usa enteros para booleanos
    map['synced'] = synced ? 1 : 0;
    return map;
  }

  factory Movimiento.fromLocalMap(Map<String, dynamic> map) {
    // Para SQLite, convertir el JSON string a lista
    dynamic rawProductos = map['productos_vendidos'];
    if (rawProductos is String && rawProductos.isNotEmpty) {
      try {
        rawProductos = jsonDecode(rawProductos);
      } catch (_) {
        rawProductos = null;
      }
    }
    
    return Movimiento(
      id: map['id'] as String,
      productoId: map['producto_id'] as String,
      productoNombre: (map['producto_nombre'] as String?) ?? 'Producto',
      usuarioId: map['usuario_id'] as String,
      usuarioNombre: (map['usuario_nombre'] as String?) ?? 'Usuario',
      usuarioFotoUrl: map['usuario_foto_url'] as String?,
      tipo: MovimientoTipo.fromValue(map['tipo'] as String),
      cantidad: (map['cantidad'] as num).toInt(),
      nota: map['nota'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),
      synced: ((map['synced'] as num?) ?? 0) == 1, // SQLite usa 0/1
      createdAt: DateTime.parse(map['created_at'] as String),
      ventaId: map['venta_id'] as String?,
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble(),
      totalVenta: (map['total_venta'] as num?)?.toDouble(),
      productosVendidos: rawProductos != null 
        ? (rawProductos as List<dynamic>).map((e) => e as String).toList()
        : null,
    );
  }
}

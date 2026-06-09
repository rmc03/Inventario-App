class CuadreItem {
  const CuadreItem({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;

  double get subtotal => precioUnitario * cantidad;

  CuadreItem copyWith({
    String? productoId,
    String? productoNombre,
    int? cantidad,
    double? precioUnitario,
  }) =>
      CuadreItem(
        productoId: productoId ?? this.productoId,
        productoNombre: productoNombre ?? this.productoNombre,
        cantidad: cantidad ?? this.cantidad,
        precioUnitario: precioUnitario ?? this.precioUnitario,
      );

  Map<String, dynamic> toJson() => {
        'producto_id': productoId,
        'producto_nombre': productoNombre,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };

  factory CuadreItem.fromJson(Map<String, dynamic> json) => CuadreItem(
        productoId: json['producto_id'] as String,
        productoNombre: json['producto_nombre'] as String,
        cantidad: (json['cantidad'] as num).toInt(),
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
      );

  Map<String, dynamic> toLocalMap() => toJson();

  factory CuadreItem.fromLocalMap(Map<String, dynamic> map) =>
      CuadreItem.fromJson(map);
}

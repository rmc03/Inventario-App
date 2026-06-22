import 'cuadre_item.dart';
import 'pago.dart';

enum VentaEstado {
  enCurso,
  completada,
  cancelada;

  String get label => switch (this) {
        VentaEstado.enCurso => 'En Curso',
        VentaEstado.completada => 'Completada',
        VentaEstado.cancelada => 'Cancelada',
      };

  static VentaEstado fromValue(String value) => switch (value) {
        'completada' => VentaEstado.completada,
        'cancelada' => VentaEstado.cancelada,
        _ => VentaEstado.enCurso,
      };
}

class Venta {
  const Venta({
    required this.id,
    required this.dependienteId,
    required this.dependienteNombre,
    this.dependienteFotoUrl,
    this.items = const [],
    this.pagos = const [],
    this.estado = VentaEstado.enCurso,
    required this.fecha,
    this.synced = false,
    required this.createdAt,
  });

  final String id;
  final String dependienteId;
  final String dependienteNombre;
  final String? dependienteFotoUrl;
  final List<CuadreItem> items;
  final List<Pago> pagos;
  final VentaEstado estado;
  final DateTime fecha;
  final bool synced;
  final DateTime createdAt;

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get totalUnidades => items.fold(0, (sum, item) => sum + item.cantidad);

  Venta copyWith({
    String? id,
    String? dependienteId,
    String? dependienteNombre,
    String? dependienteFotoUrl,
    List<CuadreItem>? items,
    List<Pago>? pagos,
    VentaEstado? estado,
    DateTime? fecha,
    bool? synced,
    DateTime? createdAt,
  }) =>
      Venta(
        id: id ?? this.id,
        dependienteId: dependienteId ?? this.dependienteId,
        dependienteNombre: dependienteNombre ?? this.dependienteNombre,
        dependienteFotoUrl: dependienteFotoUrl ?? this.dependienteFotoUrl,
        items: items ?? this.items,
        pagos: pagos ?? this.pagos,
        estado: estado ?? this.estado,
        fecha: fecha ?? this.fecha,
        synced: synced ?? this.synced,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dependiente_id': dependienteId,
        'dependiente_nombre': dependienteNombre,
        'dependiente_foto_url': dependienteFotoUrl,
        'items': items.map((i) => i.toJson()).toList(),
        'pagos': pagos.map((p) => p.toJson()).toList(),
        'estado': estado.name,
        'fecha': fecha.toIso8601String(),
        'synced': synced,
        'created_at': createdAt.toIso8601String(),
      };

  factory Venta.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    final rawPagos = json['pagos'] as List<dynamic>?;
    return Venta(
      id: json['id'] as String,
      dependienteId: json['dependiente_id'] as String,
      dependienteNombre: (json['dependiente_nombre'] as String?) ?? 'Dependiente',
      dependienteFotoUrl: json['dependiente_foto_url'] as String?,
      items: rawItems
          ?.map((i) => CuadreItem.fromJson(i as Map<String, dynamic>))
          .toList() ??
        [],
      pagos: rawPagos
          ?.map((p) => Pago.fromJson(p as Map<String, dynamic>))
          .toList() ??
        [],
      estado: VentaEstado.fromValue((json['estado'] as String?) ?? 'enCurso'),
      fecha: DateTime.parse(json['fecha'] as String),
      synced: (json['synced'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() => toJson();

  factory Venta.fromLocalMap(Map<String, dynamic> map) => Venta.fromJson(map);
}

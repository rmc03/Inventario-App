import 'cuadre_item.dart';

enum CuadreEstado {
  pendiente,
  aprobado,
  rechazado;

  String get label => switch (this) {
        CuadreEstado.pendiente => 'Pendiente',
        CuadreEstado.aprobado => 'Aprobado',
        CuadreEstado.rechazado => 'Rechazado',
      };

  static CuadreEstado fromValue(String value) => switch (value) {
        'aprobado' => CuadreEstado.aprobado,
        'rechazado' => CuadreEstado.rechazado,
        _ => CuadreEstado.pendiente,
      };
}

class Cuadre {
  const Cuadre({
    required this.id,
    required this.dependienteId,
    required this.dependienteNombre,
    required this.fechaTurno,
    this.items = const [],
    this.estado = CuadreEstado.pendiente,
    this.comentarioJefe,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  final String id;
  final String dependienteId;
  final String dependienteNombre;
  final DateTime fechaTurno;
  final List<CuadreItem> items;
  final CuadreEstado estado;
  final String? comentarioJefe;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  /// Total de unidades vendidas.
  int get totalSalidas =>
      items.fold(0, (sum, item) => sum + item.cantidad);

  /// Valor monetario total del cuadre.
  double get valorTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  Cuadre copyWith({
    String? id,
    String? dependienteId,
    String? dependienteNombre,
    DateTime? fechaTurno,
    List<CuadreItem>? items,
    CuadreEstado? estado,
    String? comentarioJefe,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) =>
      Cuadre(
        id: id ?? this.id,
        dependienteId: dependienteId ?? this.dependienteId,
        dependienteNombre: dependienteNombre ?? this.dependienteNombre,
        fechaTurno: fechaTurno ?? this.fechaTurno,
        items: items ?? this.items,
        estado: estado ?? this.estado,
        comentarioJefe: comentarioJefe ?? this.comentarioJefe,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dependiente_id': dependienteId,
        'dependiente_nombre': dependienteNombre,
        'fecha_turno': fechaTurno.toIso8601String(),
        'total_entradas': 0,
        'total_salidas': totalSalidas,
        'items': items.map((i) => i.toJson()).toList(),
        'estado': estado.name,
        'comentario_jefe': comentarioJefe,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Cuadre.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return Cuadre(
      id: json['id'] as String,
      dependienteId: json['dependiente_id'] as String,
      dependienteNombre:
          (json['dependiente_nombre'] as String?) ?? 'Dependiente',
      fechaTurno: DateTime.parse(json['fecha_turno'] as String),
      items: rawItems
              ?.map((i) => CuadreItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      estado: CuadreEstado.fromValue(
        (json['estado'] as String?) ?? 'pendiente',
      ),
      comentarioJefe: json['comentario_jefe'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      synced: (json['synced'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toLocalMap() => {...toJson(), 'synced': synced};

  factory Cuadre.fromLocalMap(Map<String, dynamic> map) =>
      Cuadre.fromJson(map);
}

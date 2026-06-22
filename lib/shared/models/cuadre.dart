import 'cuadre_item.dart';
import 'venta.dart';

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
    this.dependienteFotoUrl,
    required this.fechaTurno,
    this.ventas = const [],
    this.estado = CuadreEstado.pendiente,
    this.comentarioJefe,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  final String id;
  final String dependienteId;
  final String dependienteNombre;
  final String? dependienteFotoUrl;
  final DateTime fechaTurno;
  final List<Venta> ventas;
  final CuadreEstado estado;
  final String? comentarioJefe;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  /// Ítems aplanados de todas las ventas (para retrocompatibilidad).
  List<CuadreItem> get items => ventas.expand((v) => v.items).toList();

  /// Total de unidades vendidas.
  int get totalSalidas =>
      ventas.fold(0, (sum, venta) => sum + venta.totalUnidades);

  /// Valor monetario total del cuadre.
  double get valorTotal =>
      ventas.fold(0.0, (sum, venta) => sum + venta.total);

  Cuadre copyWith({
    String? id,
    String? dependienteId,
    String? dependienteNombre,
    DateTime? fechaTurno,
    List<Venta>? ventas,
    CuadreEstado? estado,
    String? comentarioJefe,
    String? dependienteFotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) =>
      Cuadre(
        id: id ?? this.id,
        dependienteId: dependienteId ?? this.dependienteId,
        dependienteNombre: dependienteNombre ?? this.dependienteNombre,
        fechaTurno: fechaTurno ?? this.fechaTurno,
        ventas: ventas ?? this.ventas,
        estado: estado ?? this.estado,
        comentarioJefe: comentarioJefe ?? this.comentarioJefe,
        dependienteFotoUrl: dependienteFotoUrl ?? this.dependienteFotoUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dependiente_id': dependienteId,
        'dependiente_nombre': dependienteNombre,
      'dependiente_foto_url': dependienteFotoUrl,
        'fecha_turno': fechaTurno.toIso8601String(),
        'total_entradas': 0,
        'total_salidas': totalSalidas,
        'ventas': ventas.map((v) => v.toJson()).toList(),
        'estado': estado.name,
        'comentario_jefe': comentarioJefe,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Cuadre.fromJson(Map<String, dynamic> json) {
    return Cuadre(
      id: json['id'] as String,
      dependienteId: json['dependiente_id'] as String,
      dependienteNombre:
          (json['dependiente_nombre'] as String?) ?? 'Dependiente',
      dependienteFotoUrl: json['dependiente_foto_url'] as String?,
      fechaTurno: DateTime.parse(json['fecha_turno'] as String),
      ventas: (json['ventas'] as List<dynamic>?)
              ?.map((v) => Venta.fromJson(v as Map<String, dynamic>))
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

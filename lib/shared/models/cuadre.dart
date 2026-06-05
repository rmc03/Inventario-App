enum CuadreEstado {
  pendiente,
  aprobado,
  rechazado;

  String get label {
    return switch (this) {
      CuadreEstado.pendiente => 'Pendiente',
      CuadreEstado.aprobado => 'Aprobado',
      CuadreEstado.rechazado => 'Rechazado',
    };
  }

  static CuadreEstado fromValue(String value) {
    return switch (value) {
      'aprobado' => CuadreEstado.aprobado,
      'rechazado' => CuadreEstado.rechazado,
      _ => CuadreEstado.pendiente,
    };
  }
}

class Cuadre {
  const Cuadre({
    required this.id,
    required this.dependienteId,
    required this.dependienteNombre,
    required this.fechaTurno,
    required this.totalEntradas,
    required this.totalSalidas,
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
  final int totalEntradas;
  final int totalSalidas;
  final CuadreEstado estado;
  final String? comentarioJefe;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Cuadre copyWith({
    String? id,
    String? dependienteId,
    String? dependienteNombre,
    DateTime? fechaTurno,
    int? totalEntradas,
    int? totalSalidas,
    CuadreEstado? estado,
    String? comentarioJefe,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Cuadre(
      id: id ?? this.id,
      dependienteId: dependienteId ?? this.dependienteId,
      dependienteNombre: dependienteNombre ?? this.dependienteNombre,
      fechaTurno: fechaTurno ?? this.fechaTurno,
      totalEntradas: totalEntradas ?? this.totalEntradas,
      totalSalidas: totalSalidas ?? this.totalSalidas,
      estado: estado ?? this.estado,
      comentarioJefe: comentarioJefe ?? this.comentarioJefe,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dependiente_id': dependienteId,
      'dependiente_nombre': dependienteNombre,
      'fecha_turno': fechaTurno.toIso8601String(),
      'total_entradas': totalEntradas,
      'total_salidas': totalSalidas,
      'estado': estado.name,
      'comentario_jefe': comentarioJefe,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Cuadre.fromJson(Map<String, dynamic> json) {
    return Cuadre(
      id: json['id'] as String,
      dependienteId: json['dependiente_id'] as String,
      dependienteNombre:
          (json['dependiente_nombre'] as String?) ?? 'Dependiente',
      fechaTurno: DateTime.parse(json['fecha_turno'] as String),
      totalEntradas: (json['total_entradas'] as num?)?.toInt() ?? 0,
      totalSalidas: (json['total_salidas'] as num?)?.toInt() ?? 0,
      estado: CuadreEstado.fromValue(
        (json['estado'] as String?) ?? 'pendiente',
      ),
      comentarioJefe: json['comentario_jefe'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      synced: (json['synced'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {...toJson(), 'synced': synced};
  }

  factory Cuadre.fromLocalMap(Map<String, dynamic> map) {
    return Cuadre.fromJson(map);
  }
}

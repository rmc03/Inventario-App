/// Representa un código QR para recibir transferencias bancarias.
/// 
/// En Cuba, las transferencias se realizan escaneando QRs generados
/// por las apps bancarias. Este modelo almacena esos QRs para uso
/// en el flujo de ventas.
class QrPago {
  final String id;
  final String nombre;
  final String imagenPath; // Path local en dispositivo
  final String propietarioId; // userId del dueño
  final bool esCompartido; // true si es del admin y compartido
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  const QrPago({
    required this.id,
    required this.nombre,
    required this.imagenPath,
    required this.propietarioId,
    required this.esCompartido,
    required this.creadoEn,
    this.actualizadoEn,
  });

  QrPago copyWith({
    String? id,
    String? nombre,
    String? imagenPath,
    String? propietarioId,
    bool? esCompartido,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return QrPago(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      imagenPath: imagenPath ?? this.imagenPath,
      propietarioId: propietarioId ?? this.propietarioId,
      esCompartido: esCompartido ?? this.esCompartido,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}

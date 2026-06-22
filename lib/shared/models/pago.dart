class Pago {
  const Pago({
    required this.metodo,
    required this.monto,
    this.efectivoRecibido,
  });

  final String metodo; // 'efectivo' | 'tarjeta' | 'transferencia'
  final double monto;
  final double? efectivoRecibido;

  Map<String, dynamic> toJson() => {
        'metodo': metodo,
        'monto': monto,
        'efectivo_recibido': efectivoRecibido,
      };

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        metodo: json['metodo'] as String,
        monto: (json['monto'] as num).toDouble(),
        efectivoRecibido: json['efectivo_recibido'] != null
            ? (json['efectivo_recibido'] as num).toDouble()
            : null,
      );
}

import 'package:flutter/material.dart';

enum MetodoPago {
  efectivo('Efectivo', Icons.payments_outlined),
  transferencia('Transferencia', Icons.account_balance_outlined);

  const MetodoPago(this.label, this.icon);
  final String label;
  final IconData icon;

  String get key => name;

  static MetodoPago fromKey(String key) =>
      MetodoPago.values.firstWhere((e) => e.key == key);
}

class Pago {
  const Pago({
    required this.metodo,
    required this.monto,
    this.efectivoRecibido,
    this.cambio,
  });

  final MetodoPago metodo;
  final double monto;
  final double? efectivoRecibido;
  final double? cambio;

  Pago copyWith({
    MetodoPago? metodo,
    double? monto,
    double? efectivoRecibido,
    double? cambio,
  }) =>
      Pago(
        metodo: metodo ?? this.metodo,
        monto: monto ?? this.monto,
        efectivoRecibido: efectivoRecibido ?? this.efectivoRecibido,
        cambio: cambio ?? this.cambio,
      );

  Map<String, dynamic> toJson() => {
        'metodo': metodo.key,
        'monto': monto,
        'efectivo_recibido': efectivoRecibido,
        'cambio': cambio,
      };

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        metodo: MetodoPago.fromKey(json['metodo'] as String),
        monto: (json['monto'] as num).toDouble(),
        efectivoRecibido: json['efectivo_recibido'] != null
            ? (json['efectivo_recibido'] as num).toDouble()
            : null,
        cambio: json['cambio'] != null
            ? (json['cambio'] as num).toDouble()
            : null,
      );
}

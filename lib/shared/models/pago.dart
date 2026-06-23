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
  });

  final MetodoPago metodo;
  final double monto;
  final double? efectivoRecibido;

  Map<String, dynamic> toJson() => {
        'metodo': metodo.key,
        'monto': monto,
        'efectivo_recibido': efectivoRecibido,
      };

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        metodo: MetodoPago.fromKey(json['metodo'] as String),
        monto: (json['monto'] as num).toDouble(),
        efectivoRecibido: json['efectivo_recibido'] != null
            ? (json['efectivo_recibido'] as num).toDouble()
            : null,
      );
}

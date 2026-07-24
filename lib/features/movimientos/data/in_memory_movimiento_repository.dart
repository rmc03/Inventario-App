import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../shared/models/movimiento.dart';
import 'movimiento_repository.dart';

const _uuid = Uuid();

List<Movimiento> _buildTestMovimientos() {
  final now = DateTime.now();
  final rows = <Movimiento>[];

  Movimiento m({
    required String productoId,
    required String productoNombre,
    required String usuarioId,
    required String usuarioNombre,
    required MovimientoTipo tipo,
    required int cantidad,
    required DateTime fecha,
    String? nota,
    String? ventaId,
    double? precioUnitario,
    String? usuarioFotoUrl,
  }) {
    return Movimiento(
      id: _uuid.v4(),
      productoId: productoId,
      productoNombre: productoNombre,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      usuarioFotoUrl: usuarioFotoUrl,
      tipo: tipo,
      cantidad: cantidad,
      nota: nota,
      fecha: fecha,
      synced: false,
      createdAt: fecha,
      ventaId: ventaId,
      precioUnitario: precioUnitario,
    );
  }

  const jefeId = '00000000-0000-4000-9000-000000000001';
  const jefeNombre = 'Ruslan Jefe';
  const dependienteId = '00000000-0000-4000-9000-000000000002';
  const dependienteNombre = 'Dependiente Demo';

  // ── Jun 25: Entradas iniciales (altas) ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 50,
    fecha: DateTime(2026, 6, 25, 10, 0),
    nota: 'Ingreso inicial de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 80,
    fecha: DateTime(2026, 6, 25, 10, 15),
    nota: 'Ingreso inicial de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 60,
    fecha: DateTime(2026, 6, 25, 10, 30),
    nota: 'Ingreso inicial de mercancía',
  ));

  // ── Jun 28: Más entradas ──
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 50,
    fecha: DateTime(2026, 6, 28, 9, 0),
    nota: 'Ingreso inicial de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 100,
    fecha: DateTime(2026, 6, 28, 9, 10),
    nota: 'Ingreso inicial de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 30,
    fecha: DateTime(2026, 6, 28, 9, 20),
    nota: 'Ingreso inicial de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-cafe',
    productoNombre: 'Café Cubita',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 20,
    fecha: DateTime(2026, 6, 28, 9, 30),
    nota: 'Ingreso inicial de mercancía',
  ));

  // ── Jul 1: Primeras ventas ──
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 60,
    fecha: DateTime(2026, 7, 1, 9, 0),
    nota: 'Entrada de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 20,
    fecha: DateTime(2026, 7, 1, 9, 15),
    nota: 'Entrada de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 1, 11, 0),
    nota: 'Venta POS #001',
    ventaId: 'venta-001',
    precioUnitario: 500.0,
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 1, 11, 0),
    nota: 'Venta POS #001',
    ventaId: 'venta-001',
    precioUnitario: 650.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 1, 15, 30),
    nota: 'Venta POS #002',
    ventaId: 'venta-002',
    precioUnitario: 200.0,
  ));

  // ── Jul 3: Ventas ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 3, 10, 0),
    nota: 'Venta POS #003',
    ventaId: 'venta-003',
    precioUnitario: 1600.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(2026, 7, 3, 10, 0),
    nota: 'Venta POS #003',
    ventaId: 'venta-003',
    precioUnitario: 280.0,
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 3, 14, 30),
    nota: 'Venta POS #004',
    ventaId: 'venta-004',
    precioUnitario: 850.0,
  ));

  // ── Jul 5: Entrada + Venta ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 20,
    fecha: DateTime(2026, 7, 5, 9, 0),
    nota: 'Reposición de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(2026, 7, 5, 14, 0),
    nota: 'Venta POS #005',
    ventaId: 'venta-005',
    precioUnitario: 500.0,
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 5, 14, 0),
    nota: 'Venta POS #005',
    ventaId: 'venta-005',
    precioUnitario: 2200.0,
  ));

  // ── Jul 7: Venta ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 8,
    fecha: DateTime(2026, 7, 7, 12, 0),
    nota: 'Venta POS #006',
    ventaId: 'venta-006',
    precioUnitario: 650.0,
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 7, 12, 0),
    nota: 'Venta POS #006',
    ventaId: 'venta-006',
    precioUnitario: 500.0,
  ));
  rows.add(m(
    productoId: 'prod-cafe',
    productoNombre: 'Café Cubita',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(2026, 7, 7, 16, 30),
    nota: 'Venta POS #007',
    ventaId: 'venta-007',
    precioUnitario: 2000.0,
  ));

  // ── Jul 8: Venta de huevos ──
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 8, 11, 0),
    nota: 'Venta POS #008',
    ventaId: 'venta-008',
    precioUnitario: 2700.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 12,
    fecha: DateTime(2026, 7, 8, 18, 0),
    nota: 'Venta POS #009',
    ventaId: 'venta-009',
    precioUnitario: 280.0,
  ));

  // ── Jul 9: Venta grande ──
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 9, 16, 0),
    nota: 'Venta POS #010',
    ventaId: 'venta-010',
    precioUnitario: 200.0,
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 9, 16, 0),
    nota: 'Venta POS #010',
    ventaId: 'venta-010',
    precioUnitario: 850.0,
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 9, 16, 0),
    nota: 'Venta POS #010',
    ventaId: 'venta-010',
    precioUnitario: 650.0,
  ));

  // ── Jul 10: Entrada de mercancía ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 30,
    fecha: DateTime(2026, 7, 10, 9, 0),
    nota: 'Reposición de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 25,
    fecha: DateTime(2026, 7, 10, 9, 15),
    nota: 'Reposición de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 10, 10, 0),
    nota: 'Venta POS #011',
    ventaId: 'venta-011',
    precioUnitario: 850.0,
  ));

  // ── Jul 11: Venta ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 11, 11, 30),
    nota: 'Venta POS #012',
    ventaId: 'venta-012',
    precioUnitario: 1600.0,
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 11, 11, 30),
    nota: 'Venta POS #012',
    ventaId: 'venta-012',
    precioUnitario: 2200.0,
  ));

  // ── Jul 12: Venta grande con múltiples productos ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #013',
    ventaId: 'venta-013',
    precioUnitario: 650.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #013',
    ventaId: 'venta-013',
    precioUnitario: 280.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #013',
    ventaId: 'venta-013',
    precioUnitario: 200.0,
  ));
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #013',
    ventaId: 'venta-013',
    precioUnitario: 2700.0,
  ));

  // ── Jul 14: Ajuste de stock ──
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 40,
    fecha: DateTime(2026, 7, 14, 9, 0),
    nota: 'Ajuste de inventario (entrada)',
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 36,
    fecha: DateTime(2026, 7, 14, 9, 15),
    nota: 'Reposición de mercancía',
  ));

  // ── Jul 15: Ventas ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 15, 10, 30),
    nota: 'Venta POS #014',
    ventaId: 'venta-014',
    precioUnitario: 500.0,
  ));
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 15, 10, 30),
    nota: 'Venta POS #014',
    ventaId: 'venta-014',
    precioUnitario: 1600.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 12,
    fecha: DateTime(2026, 7, 15, 14, 0),
    nota: 'Venta POS #015',
    ventaId: 'venta-015',
    precioUnitario: 280.0,
  ));

  // ── Jul 16: Venta de pollo ──
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 16, 15, 0),
    nota: 'Venta POS #016',
    ventaId: 'venta-016',
    precioUnitario: 2200.0,
  ));

  // ── Jul 17: Venta grande ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 10,
    fecha: DateTime(2026, 7, 17, 13, 0),
    nota: 'Venta POS #017',
    ventaId: 'venta-017',
    precioUnitario: 650.0,
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 8,
    fecha: DateTime(2026, 7, 17, 13, 0),
    nota: 'Venta POS #017',
    ventaId: 'venta-017',
    precioUnitario: 850.0,
  ));

  // ── Jul 18: Reposición ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 30,
    fecha: DateTime(2026, 7, 18, 9, 0),
    nota: 'Reposición de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 20,
    fecha: DateTime(2026, 7, 18, 9, 15),
    nota: 'Reposición de mercancía',
  ));

  // ── Jul 19: Ventas ──
  rows.add(m(
    productoId: 'prod-cafe',
    productoNombre: 'Café Cubita',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 19, 10, 0),
    nota: 'Venta POS #018',
    ventaId: 'venta-018',
    precioUnitario: 2000.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 8,
    fecha: DateTime(2026, 7, 19, 15, 0),
    nota: 'Venta POS #019',
    ventaId: 'venta-019',
    precioUnitario: 200.0,
  ));

  // ── Jul 20: Ventas + Entrada ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 25,
    fecha: DateTime(2026, 7, 20, 9, 0),
    nota: 'Reposición de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 20, 11, 0),
    nota: 'Venta POS #020',
    ventaId: 'venta-020',
    precioUnitario: 500.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 20, 11, 0),
    nota: 'Venta POS #020',
    ventaId: 'venta-020',
    precioUnitario: 200.0,
  ));
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(2026, 7, 20, 16, 0),
    nota: 'Venta POS #021',
    ventaId: 'venta-021',
    precioUnitario: 2700.0,
  ));

  // ── Jul 21: Movimientos del día actual ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(now.year, now.month, now.day, 9, 30),
    nota: 'Venta POS #022',
    ventaId: 'venta-022',
    precioUnitario: 500.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(now.year, now.month, now.day, 9, 30),
    nota: 'Venta POS #022',
    ventaId: 'venta-022',
    precioUnitario: 200.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(now.year, now.month, now.day, 14, 0),
    nota: 'Venta POS #023',
    ventaId: 'venta-023',
    precioUnitario: 280.0,
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(now.year, now.month, now.day, 14, 0),
    nota: 'Venta POS #023',
    ventaId: 'venta-023',
    precioUnitario: 2200.0,
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(now.year, now.month, now.day, 16, 30),
    nota: 'Venta POS #024',
    ventaId: 'venta-024',
    precioUnitario: 650.0,
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(now.year, now.month, now.day, 16, 30),
    nota: 'Venta POS #024',
    ventaId: 'venta-024',
    precioUnitario: 850.0,
  ));

  // ═══════════════════════════════════════════════════════════════════════════
  // ── DATOS ADICIONALES PARA TESTING ──
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Jul 22: Ajustes manuales del admin (positivos y negativos) ──
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 10,
    fecha: DateTime(2026, 7, 22, 8, 30),
    nota: 'Ajuste manual: +10 unidades',
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: -5,
    fecha: DateTime(2026, 7, 22, 8, 45),
    nota: 'Ajuste manual: -5 unidades',
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: -3,
    fecha: DateTime(2026, 7, 22, 9, 0),
    nota: 'Ajuste manual: -3 unidades',
  ));

  // ── Jul 22: Ventas variadas ──
  rows.add(m(
    productoId: 'prod-cafe',
    productoNombre: 'Café Cubita',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(2026, 7, 22, 11, 15),
    nota: 'Venta POS #025',
    ventaId: 'venta-025',
    precioUnitario: 2000.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(2026, 7, 22, 11, 15),
    nota: 'Venta POS #025',
    ventaId: 'venta-025',
    precioUnitario: 280.0,
  ));

  // ── Jul 23: Entradas matutinas ──
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 15,
    fecha: DateTime(2026, 7, 23, 8, 0),
    nota: 'Reposición de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 25,
    fecha: DateTime(2026, 7, 23, 8, 15),
    nota: 'Reposición de mercancía',
  ));

  // ── Jul 23: Venta de 5 productos ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 23, 13, 30),
    nota: 'Venta POS #026',
    ventaId: 'venta-026',
    precioUnitario: 1600.0,
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 23, 13, 30),
    nota: 'Venta POS #026',
    ventaId: 'venta-026',
    precioUnitario: 850.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Suchel 180 Mg',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 23, 13, 30),
    nota: 'Venta POS #026',
    ventaId: 'venta-026',
    precioUnitario: 200.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(2026, 7, 23, 13, 30),
    nota: 'Venta POS #026',
    ventaId: 'venta-026',
    precioUnitario: 280.0,
  ));
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 23, 13, 30),
    nota: 'Venta POS #026',
    ventaId: 'venta-026',
    precioUnitario: 2700.0,
  ));

  // ── Jul 23: Ventas de tarde/noche ──
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 12,
    fecha: DateTime(2026, 7, 23, 18, 45),
    nota: 'Venta POS #027',
    ventaId: 'venta-027',
    precioUnitario: 280.0,
  ));
  rows.add(m(
    productoId: 'prod-pollo',
    productoNombre: 'Muslo de Pollo 2 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 23, 19, 15),
    nota: 'Venta POS #028',
    ventaId: 'venta-028',
    precioUnitario: 2200.0,
  ));

  // ── Hoy (Día actual): Movimientos variados desde la mañana ──
  rows.add(m(
    productoId: 'prod-huevos',
    productoNombre: 'File de Huevos',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 1,
    fecha: DateTime(now.year, now.month, now.day, 11, 51),
    nota: 'Alta de producto',
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: -5,
    fecha: DateTime(now.year, now.month, now.day, 12, 11),
    nota: 'Ajuste manual: -5 unidades',
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 10,
    fecha: DateTime(now.year, now.month, now.day, 12, 21),
    nota: 'Ajuste manual: +10 unidades',
  ));

  // ── Hoy: Venta con 2 productos ──
  rows.add(m(
    productoId: 'prod-cafe',
    productoNombre: 'Café Cubita',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(now.year, now.month, now.day, 12, 24),
    nota: 'Venta POS #029',
    ventaId: 'venta-029',
    precioUnitario: 2000.0,
  ));
  rows.add(m(
    productoId: 'prod-cerveza',
    productoNombre: 'Cerveza La Fría',
    usuarioId: dependienteId,
    usuarioNombre: dependienteNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(now.year, now.month, now.day, 12, 24),
    nota: 'Venta POS #029',
    ventaId: 'venta-029',
    precioUnitario: 280.0,
  ));

  // ── Hoy: Entrada de tarde ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.entrada,
    cantidad: 20,
    fecha: DateTime(now.year, now.month, now.day, 14, 5),
    nota: 'Reposición de mercancía',
  ));

  // ── Hoy: Venta grande de 4 productos ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Bolsa de Arroz Importado 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(now.year, now.month, now.day, 15, 40),
    nota: 'Venta POS #030',
    ventaId: 'venta-030',
    precioUnitario: 650.0,
  ));
  rows.add(m(
    productoId: 'prod-frijoles',
    productoNombre: 'Frijoles Importados 1 Kg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(now.year, now.month, now.day, 15, 40),
    nota: 'Venta POS #030',
    ventaId: 'venta-030',
    precioUnitario: 850.0,
  ));
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite de Girasol 900 Ml',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(now.year, now.month, now.day, 15, 40),
    nota: 'Venta POS #030',
    ventaId: 'venta-030',
    precioUnitario: 1600.0,
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente 500 Mg',
    usuarioId: jefeId,
    usuarioNombre: jefeNombre,
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(now.year, now.month, now.day, 15, 40),
    nota: 'Venta POS #030',
    ventaId: 'venta-030',
    precioUnitario: 500.0,
  ));

  return rows;
}

class InMemoryMovimientoRepository implements MovimientoRepository {
  InMemoryMovimientoRepository() {
    _movimientos.addAll(_buildTestMovimientos());
    _controller.add(List.unmodifiable(_movimientos));
  }

  final List<Movimiento> _movimientos = [];
  final StreamController<List<Movimiento>> _controller =
      StreamController<List<Movimiento>>.broadcast();

  @override
  Stream<List<Movimiento>> get movimientosStream => _controller.stream;

  @override
  Future<void> ensureLoaded() async {
    _controller.add(List.unmodifiable(_movimientos));
  }

  @override
  List<Movimiento> fetchMovimientos() {
    return List.unmodifiable(_movimientos);
  }

  @override
  void addMovimiento(Movimiento movimiento) {
    _movimientos.insert(0, movimiento);
    _controller.add(List.unmodifiable(_movimientos));
  }

  @override
  void updateMovimiento(Movimiento movimiento) {
    final idx = _movimientos.indexWhere((m) => m.id == movimiento.id);
    if (idx != -1) {
      _movimientos[idx] = movimiento;
      _controller.add(List.unmodifiable(_movimientos));
    }
  }

  @override
  Future<List<Movimiento>> getMovimientos(MovimientosFilterState filtro) async {
    return filtrarMovimientos(fetchMovimientos(), filtro);
  }

  @override
  Future<List<Movimiento>> fetchMovimientosForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _movimientos.where((m) {
      return m.fecha.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          m.fecha.isBefore(end);
    }).toList();
  }

  void dispose() {
    _controller.close();
  }
}

import 'package:uuid/uuid.dart';

import '../../../shared/models/movimiento.dart';

const _uuid = Uuid();

/// Builds test movements for in-memory storage (demo/testing only).
/// Returns a list of 30 movements across 12 dates using demo products and users.
List<Movimiento> buildTestMovimientos() {
  final now = DateTime.now();
  final rows = <Movimiento>[];

  String id() => _uuid.v4();

  // Helper to create a movement
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
  }) {
    return Movimiento(
      id: id(),
      productoId: productoId,
      productoNombre: productoNombre,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      usuarioFotoUrl: null,
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

  // ── Jun 25: Entradas iniciales (altas) ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 50,
    fecha: DateTime(2026, 6, 25, 10, 0),
    nota: 'Alta de producto',
  ));
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite Cocinero 900ml',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 60,
    fecha: DateTime(2026, 6, 25, 10, 15),
    nota: 'Alta de producto',
  ));

  // ── Jun 28: Más altas ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Arroz Diana 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 80,
    fecha: DateTime(2026, 6, 28, 9, 0),
    nota: 'Alta de producto',
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 100,
    fecha: DateTime(2026, 6, 28, 9, 10),
    nota: 'Alta de producto',
  ));
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 150,
    fecha: DateTime(2026, 6, 28, 9, 20),
    nota: 'Alta de producto',
  ));

  // ── Jul 1: Primeras ventas ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 1, 11, 0),
    nota: 'Venta POS #test001',
    ventaId: 'test-venta-001',
    precioUnitario: 45.0,
  ));
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Arroz Diana 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 1, 11, 0),
    nota: 'Venta POS #test001',
    ventaId: 'test-venta-001',
    precioUnitario: 12.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 1, 15, 30),
    nota: 'Venta POS #test002',
    ventaId: 'test-venta-002',
    precioUnitario: 8.0,
  ));

  // ── Jul 3: Ventas ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite Cocinero 900ml',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 3, 10, 0),
    nota: 'Venta POS #test003',
    ventaId: 'test-venta-003',
    precioUnitario: 35.0,
  ));
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 3, 10, 0),
    nota: 'Venta POS #test003',
    ventaId: 'test-venta-003',
    precioUnitario: 5.0,
  ));

  // ── Jul 5: Entrada + Venta ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite Cocinero 900ml',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 20,
    fecha: DateTime(2026, 7, 5, 9, 0),
    nota: 'Entrada de mercancía',
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(2026, 7, 5, 14, 0),
    nota: 'Venta POS #test004',
    ventaId: 'test-venta-004',
    precioUnitario: 45.0,
  ));

  // ── Jul 7: Venta ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Arroz Diana 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 8,
    fecha: DateTime(2026, 7, 7, 12, 0),
    nota: 'Venta POS #test005',
    ventaId: 'test-venta-005',
    precioUnitario: 12.0,
  ));
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 7, 12, 0),
    nota: 'Venta POS #test005',
    ventaId: 'test-venta-005',
    precioUnitario: 45.0,
  ));

  // ── Jul 9: Venta grande ──
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 10,
    fecha: DateTime(2026, 7, 9, 16, 0),
    nota: 'Venta POS #test006',
    ventaId: 'test-venta-006',
    precioUnitario: 5.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 9, 16, 0),
    nota: 'Venta POS #test006',
    ventaId: 'test-venta-006',
    precioUnitario: 8.0,
  ));

  // ── Jul 10: Entrada ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 30,
    fecha: DateTime(2026, 7, 10, 9, 0),
    nota: 'Entrada de mercancía',
  ));

  // ── Jul 11: Venta ──
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite Cocinero 900ml',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 11, 11, 30),
    nota: 'Venta POS #test007',
    ventaId: 'test-venta-007',
    precioUnitario: 35.0,
  ));

  // ── Jul 12: Venta grande con 3 productos ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Arroz Diana 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #test008',
    ventaId: 'test-venta-008',
    precioUnitario: 12.0,
  ));
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 6,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #test008',
    ventaId: 'test-venta-008',
    precioUnitario: 5.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 3,
    fecha: DateTime(2026, 7, 12, 14, 0),
    nota: 'Venta POS #test008',
    ventaId: 'test-venta-008',
    precioUnitario: 8.0,
  ));

  // ── Jul 14: Ajuste de stock ──
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 40,
    fecha: DateTime(2026, 7, 14, 9, 0),
    nota: 'Ajuste de stock (entrada)',
  ));

  // ── Jul 15: Venta ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 5,
    fecha: DateTime(2026, 7, 15, 10, 30),
    nota: 'Venta POS #test009',
    ventaId: 'test-venta-009',
    precioUnitario: 45.0,
  ));
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite Cocinero 900ml',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 15, 10, 30),
    nota: 'Venta POS #test009',
    ventaId: 'test-venta-009',
    precioUnitario: 35.0,
  ));

  // ── Jul 17: Venta grande ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Arroz Diana 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 10,
    fecha: DateTime(2026, 7, 17, 13, 0),
    nota: 'Venta POS #test010',
    ventaId: 'test-venta-010',
    precioUnitario: 12.0,
  ));

  // ── Jul 18: Alta extra ──
  rows.add(m(
    productoId: 'prod-arroz',
    productoNombre: 'Arroz Diana 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 30,
    fecha: DateTime(2026, 7, 18, 9, 0),
    nota: 'Alta de producto',
  ));

  // ── Jul 19: Venta ──
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 8,
    fecha: DateTime(2026, 7, 19, 15, 0),
    nota: 'Venta POS #test011',
    ventaId: 'test-venta-011',
    precioUnitario: 5.0,
  ));

  // ── Jul 20: Venta + Entrada ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 4,
    fecha: DateTime(2026, 7, 20, 11, 0),
    nota: 'Venta POS #test012',
    ventaId: 'test-venta-012',
    precioUnitario: 45.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(2026, 7, 20, 11, 0),
    nota: 'Venta POS #test012',
    ventaId: 'test-venta-012',
    precioUnitario: 8.0,
  ));
  rows.add(m(
    productoId: 'prod-aceite',
    productoNombre: 'Aceite Cocinero 900ml',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 10,
    fecha: DateTime(2026, 7, 20, 9, 0),
    nota: 'Entrada de mercancía',
  ));

  // ── Jul 21 (hoy): Ventas + Entrada ──
  rows.add(m(
    productoId: 'prod-detergente',
    productoNombre: 'Detergente Ariel 1kg',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(now.year, now.month, now.day, 9, 30),
    nota: 'Venta POS #test013',
    ventaId: 'test-venta-013',
    precioUnitario: 45.0,
  ));
  rows.add(m(
    productoId: 'prod-jabon',
    productoNombre: 'Jabón Protex x3',
    usuarioId: '00000000-0000-4000-9000-000000000002',
    usuarioNombre: 'Dependiente Demo',
    tipo: MovimientoTipo.salida,
    cantidad: 1,
    fecha: DateTime(now.year, now.month, now.day, 9, 30),
    nota: 'Venta POS #test013',
    ventaId: 'test-venta-013',
    precioUnitario: 8.0,
  ));
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.salida,
    cantidad: 2,
    fecha: DateTime(now.year, now.month, now.day, 14, 0),
    nota: 'Venta POS #test014',
    ventaId: 'test-venta-014',
    precioUnitario: 5.0,
  ));
  rows.add(m(
    productoId: 'prod-bolsas',
    productoNombre: 'Bolsas de Nylon',
    usuarioId: '00000000-0000-4000-9000-000000000001',
    usuarioNombre: 'Jefe',
    tipo: MovimientoTipo.entrada,
    cantidad: 50,
    fecha: DateTime(now.year, now.month, now.day, 16, 0),
    nota: 'Entrada de mercancía',
  ));

  return rows;
}
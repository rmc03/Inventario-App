import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';
import '../../../shared/models/usuario.dart';
import '../data/movimiento_repository.dart';
import '../data/in_memory_movimiento_repository.dart';

final movimientoRepositoryProvider = Provider<MovimientoRepository>((ref) {
  // Using InMemory repository with test data for development
  return InMemoryMovimientoRepository();
});

// ─── Estado de filtros compartido (una sola fuente para toda la pantalla) ───

final movimientosFilterProvider =
    NotifierProvider<MovimientosFilterNotifier, MovimientosFilterState>(
      MovimientosFilterNotifier.new,
    );

class MovimientosFilterNotifier extends Notifier<MovimientosFilterState> {
  @override
  MovimientosFilterState build() => const MovimientosFilterState();

  void setTipo(TipoMovimientoFiltro tipo) =>
      state = state.copyWith(tipo: tipo);

  void setRango(RangoFechaFiltro rango) =>
      state = state.copyWith(rango: rango);

  void setRangoPersonalizado(DateTime? inicio, DateTime? fin) => state =
      state.copyWith(
        rango: RangoFechaFiltro.personalizado,
        fechaInicioCustom: inicio,
        fechaFinCustom: fin,
      );

  void setQuery(String query) => state = state.copyWith(query: query);

  void limpiar() => state = const MovimientosFilterState();
}

/// Lista de movimientos ya filtrada (tipo + fecha + búsqueda), derivada de
/// forma reactiva del listado en vivo y del estado de filtros compartido.
/// Ambas pestañas la consumen, por lo que un cambio de filtro refresca las dos.
final movimientosFiltradosProvider = Provider<List<Movimiento>>((ref) {
  final source = ref.watch(movimientoControllerProvider);
  final filtro = ref.watch(movimientosFilterProvider);
  return filtrarMovimientos(source, filtro);
});

// NOTE: current cuadre sales are computed from `cuadres` state (see cuadre_provider)
final currentCuadreSalesProvider = Provider<Map<String, int>>((ref) {
  final movimientos = ref.watch(movimientoControllerProvider);
  final counts = <String, int>{};
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  for (final m in movimientos) {
    if (m.tipo == MovimientoTipo.salida && m.fecha.isAfter(start.subtract(const Duration(seconds: 1)))) {
      counts[m.productoId] = (counts[m.productoId] ?? 0) + m.cantidad;
    }
  }
  return counts;
});

final movimientoControllerProvider =
    NotifierProvider<MovimientoController, List<Movimiento>>(
      MovimientoController.new,
    );

class MovimientoController extends Notifier<List<Movimiento>> {
  MovimientoRepository get _repository =>
      ref.read(movimientoRepositoryProvider);

  @override
  List<Movimiento> build() {
    // Ensure repository loaded and keep controller in sync with repository
    unawaited(_repository.ensureLoaded());

    // Subscribe to repository stream so external writes update this state
    final sub = _repository.movimientosStream.listen((list) {
      if (!ref.mounted) return;
      state = list;
    });
    ref.onDispose(() => sub.cancel());

    return _repository.fetchMovimientos();
  }

  void registrarMovimiento({
    required Producto producto,
    required Usuario usuario,
    required MovimientoTipo tipo,
    required int cantidad,
    String? nota,
  }) {
    final now = DateTime.now();
    final movimiento = Movimiento(
      id: const Uuid().v4(),
      productoId: producto.id,
      productoNombre: producto.nombre,
      usuarioId: usuario.id,
      usuarioNombre: usuario.nombre,
      usuarioFotoUrl: usuario.fotoUrl,
      tipo: tipo,
      cantidad: cantidad,
      nota: nota == null || nota.trim().isEmpty ? null : nota.trim(),
      fecha: now,
      synced: false,
      createdAt: now,
    );

    _repository.addMovimiento(movimiento);
    state = _repository.fetchMovimientos();
  }

  /// Registra el inicio de turno de un dependiente
  void registrarInicioTurno({
    required Usuario dependiente,
  }) {
    final now = DateTime.now();
    final movimiento = Movimiento(
      id: const Uuid().v4(),
      productoId: '', // No aplica para inicio de turno
      productoNombre: '', // No aplica
      usuarioId: dependiente.id,
      usuarioNombre: dependiente.nombre,
      usuarioFotoUrl: dependiente.fotoUrl,
      tipo: MovimientoTipo.inicioTurno,
      cantidad: 0, // No aplica
      nota: 'Inicio de turno de ${dependiente.nombre}',
      fecha: now,
      synced: false,
      createdAt: now,
    );

    _repository.addMovimiento(movimiento);
    state = _repository.fetchMovimientos();
  }

  /// Registra una venta completa con todos sus productos
  void registrarVenta({
    required String ventaId,
    required Usuario dependiente,
    required List<Map<String, dynamic>> productos, // [{nombre: String, cantidad: int, precio: double}]
    required double totalVenta,
  }) {
    final now = DateTime.now();
    final productosNombres = productos.map((p) => 
      '${p['cantidad']}x ${p['nombre']}'
    ).toList();

    final movimiento = Movimiento(
      id: const Uuid().v4(),
      productoId: '', // Para ventas agrupadas, no hay un solo producto
      productoNombre: '${productos.length} productos',
      usuarioId: dependiente.id,
      usuarioNombre: dependiente.nombre,
      usuarioFotoUrl: dependiente.fotoUrl,
      tipo: MovimientoTipo.venta,
      cantidad: productos.fold<int>(0, (sum, p) => sum + (p['cantidad'] as int)),
      nota: 'Venta #${ventaId.substring(0, 8)}',
      fecha: now,
      synced: false,
      createdAt: now,
      ventaId: ventaId,
      totalVenta: totalVenta,
      productosVendidos: productosNombres,
    );

    _repository.addMovimiento(movimiento);
    state = _repository.fetchMovimientos();
  }

  /// Registra la eliminación de un producto
  void registrarProductoEliminado({
    required Producto producto,
    required Usuario admin,
    String? motivo,
  }) {
    final now = DateTime.now();
    final movimiento = Movimiento(
      id: const Uuid().v4(),
      productoId: producto.id,
      productoNombre: producto.nombre,
      usuarioId: admin.id,
      usuarioNombre: admin.nombre,
      usuarioFotoUrl: admin.fotoUrl,
      tipo: MovimientoTipo.productoEliminado,
      cantidad: producto.stockActual, // Guardamos el stock que tenía
      nota: motivo,
      fecha: now,
      synced: false,
      createdAt: now,
    );

    _repository.addMovimiento(movimiento);
    state = _repository.fetchMovimientos();
  }
}

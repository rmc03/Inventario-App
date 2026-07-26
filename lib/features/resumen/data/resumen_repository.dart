import '../../../shared/models/movimiento.dart';
import '../../../shared/models/cuadre.dart';
import '../../movimientos/data/movimiento_repository.dart';
import '../../inventario/data/producto_repository.dart';
import '../../cuadres/data/cuadre_repository.dart';

/// Rango de período para filtrado de datos en el resumen.
enum PeriodoResumen {
  hoy,
  semana,
  mes;

  String get label => switch (this) {
        PeriodoResumen.hoy => 'Hoy',
        PeriodoResumen.semana => 'Esta semana',
        PeriodoResumen.mes => 'Este mes',
      };

  /// Calcula el inicio del período.
  DateTime inicio() {
    final now = DateTime.now();
    return switch (this) {
      PeriodoResumen.hoy => DateTime(now.year, now.month, now.day),
      PeriodoResumen.semana => _inicioSemana(now),
      PeriodoResumen.mes => DateTime(now.year, now.month, 1),
    };
  }

  /// Calcula el fin del período.
  DateTime fin() {
    final now = DateTime.now();
    return switch (this) {
      PeriodoResumen.hoy => now,
      PeriodoResumen.semana => now,
      PeriodoResumen.mes => now,
    };
  }

  /// Calcula el inicio del período anterior equivalente.
  DateTime inicioAnterior() {
    final inicioActual = inicio();
    return switch (this) {
      PeriodoResumen.hoy => inicioActual.subtract(const Duration(days: 1)),
      PeriodoResumen.semana => inicioActual.subtract(const Duration(days: 7)),
      PeriodoResumen.mes => DateTime(
          inicioActual.year,
          inicioActual.month - 1,
          inicioActual.day,
        ),
    };
  }

  /// Calcula el fin del período anterior equivalente.
  DateTime finAnterior() {
    return inicio().subtract(const Duration(milliseconds: 1));
  }

  static DateTime _inicioSemana(DateTime fecha) {
    final diaSemana = fecha.weekday;
    return DateTime(fecha.year, fecha.month, fecha.day)
        .subtract(Duration(days: diaSemana - 1));
  }
}

/// Producto vendido con su cantidad y valor monetario en un período.
class ProductoVendido {
  const ProductoVendido({
    required this.productoId,
    required this.nombre,
    required this.unidades,
    required this.valorTotal,
  });

  final String productoId;
  final String nombre;
  final int unidades;
  final double valorTotal;
}

/// Datos agregados del resumen para un período.
class DatosResumen {
  const DatosResumen({
    required this.ventasTotales,
    required this.unidadesVendidas,
    required this.ventasTotalesAnteriores,
    required this.unidadesVendidasAnteriores,
    required this.topProductos,
    required this.productosStockBajo,
    required this.cuadresPendientes,
    required this.tendenciaVentas,
  });

  final double ventasTotales;
  final int unidadesVendidas;
  final double ventasTotalesAnteriores;
  final int unidadesVendidasAnteriores;
  final List<ProductoVendido> topProductos;
  final int productosStockBajo;
  final int cuadresPendientes;
  final List<double> tendenciaVentas;

  /// Delta de ventas vs período anterior (0-1 range). Null si no hay datos anteriores.
  double? get deltaVentas {
    if (ventasTotalesAnteriores == 0) return ventasTotales > 0 ? 1.0 : null;
    return (ventasTotales - ventasTotalesAnteriores) / ventasTotalesAnteriores;
  }

  /// Delta de unidades vs período anterior. Null si no hay datos anteriores.
  double? get deltaUnidades {
    if (unidadesVendidasAnteriores == 0) {
      return unidadesVendidas > 0 ? 1.0 : null;
    }
    return (unidadesVendidas - unidadesVendidasAnteriores) /
        unidadesVendidasAnteriores;
  }

  static const empty = DatosResumen(
    ventasTotales: 0,
    unidadesVendidas: 0,
    ventasTotalesAnteriores: 0,
    unidadesVendidasAnteriores: 0,
    topProductos: [],
    productosStockBajo: 0,
    cuadresPendientes: 0,
    tendenciaVentas: [],
  );
}

/// Repositorio de agregación de datos para la pantalla de resumen.
/// No accede a SQLite/Supabase directo; reutiliza los repositorios existentes.
class ResumenRepository {
  const ResumenRepository({
    required this._movimientoRepo,
    required this._productoRepo,
    required this._cuadreRepo,
  });

  final MovimientoRepository _movimientoRepo;
  final ProductoRepository _productoRepo;
  final CuadreRepository _cuadreRepo;

  /// Calcula el resumen para el período seleccionado.
  DatosResumen calcularResumen(PeriodoResumen periodo) {
    final inicio = periodo.inicio();
    final fin = periodo.fin();

    // 1. Filtrar movimientos de venta en el período actual
    final movimientos = _movimientoRepo.fetchMovimientos();
    final ventas = _filtrarVentas(movimientos, inicio, fin);

    // 2. Ventas totales y unidades vendidas
    final ventasTotales = ventas.fold<double>(
      0.0,
      (sum, m) => sum + (m.precioUnitario ?? 0.0) * m.cantidad,
    );
    final unidadesVendidas = ventas.fold<int>(
      0,
      (sum, m) => sum + m.cantidad,
    );

    // 3. Período anterior para deltas
    final inicioAnt = periodo.inicioAnterior();
    final finAnt = periodo.finAnterior();
    final ventasAnteriores = _filtrarVentas(movimientos, inicioAnt, finAnt);
    final ventasTotalesAnteriores = ventasAnteriores.fold<double>(
      0.0,
      (sum, m) => sum + (m.precioUnitario ?? 0.0) * m.cantidad,
    );
    final unidadesVendidasAnteriores = ventasAnteriores.fold<int>(
      0,
      (sum, m) => sum + m.cantidad,
    );

    // 4. Top productos vendidos
    final topProductos = _agregarTopProductos(ventas);

    // 5. Productos con stock bajo
    final productos = _productoRepo.fetchProductos();
    final productosStockBajo = productos
        .where((p) => p.activo && p.stockActual <= p.stockMinimo)
        .length;

    // 6. Cuadres pendientes
    final cuadres = _cuadreRepo.fetchCuadres();
    final cuadresPendientes =
        cuadres.where((c) => c.estado == CuadreEstado.pendiente).length;

    // 7. Tendencia de ventas adaptada al período
    final tendencia = _calcularTendencia(movimientos, periodo);

    return DatosResumen(
      ventasTotales: ventasTotales,
      unidadesVendidas: unidadesVendidas,
      ventasTotalesAnteriores: ventasTotalesAnteriores,
      unidadesVendidasAnteriores: unidadesVendidasAnteriores,
      topProductos: topProductos,
      productosStockBajo: productosStockBajo,
      cuadresPendientes: cuadresPendientes,
      tendenciaVentas: tendencia,
    );
  }

  List<Movimiento> _filtrarVentas(
    List<Movimiento> movimientos,
    DateTime inicio,
    DateTime fin,
  ) {
    return movimientos.where((m) {
      return m.tipo == MovimientoTipo.salida &&
          m.ventaId != null &&
          m.fecha.isAfter(inicio.subtract(const Duration(milliseconds: 1))) &&
          m.fecha.isBefore(fin.add(const Duration(milliseconds: 1)));
    }).toList();
  }

  List<ProductoVendido> _agregarTopProductos(List<Movimiento> ventas) {
    final ventasPorProducto = <String, ProductoVendido>{};
    for (final m in ventas) {
      final actual = ventasPorProducto[m.productoId];
      if (actual == null) {
        ventasPorProducto[m.productoId] = ProductoVendido(
          productoId: m.productoId,
          nombre: m.productoNombre,
          unidades: m.cantidad,
          valorTotal: (m.precioUnitario ?? 0.0) * m.cantidad,
        );
      } else {
        ventasPorProducto[m.productoId] = ProductoVendido(
          productoId: actual.productoId,
          nombre: actual.nombre,
          unidades: actual.unidades + m.cantidad,
          valorTotal: actual.valorTotal + (m.precioUnitario ?? 0.0) * m.cantidad,
        );
      }
    }

    final sorted = ventasPorProducto.values.toList()
      ..sort((a, b) => b.unidades.compareTo(a.unidades));
    return sorted.take(5).toList();
  }

  /// Calcula la tendencia de ventas adaptada al período seleccionado.
  List<double> _calcularTendencia(
    List<Movimiento> movimientos,
    PeriodoResumen periodo,
  ) {
    final now = DateTime.now();
    return switch (periodo) {
      PeriodoResumen.hoy => _tendenciaPorHoras(movimientos, now),
      PeriodoResumen.semana => _tendenciaPorDias(movimientos, now, 7),
      PeriodoResumen.mes => _tendenciaPorDias(movimientos, now, 30),
    };
  }

  /// Tendencia intradía: ventas por hora de las últimas 12 horas.
  List<double> _tendenciaPorHoras(List<Movimiento> movimientos, DateTime now) {
    final tendencia = <double>[];
    for (int i = 11; i >= 0; i--) {
      final hora = now.subtract(Duration(hours: i));
      final inicio = DateTime(hora.year, hora.month, hora.day, hora.hour);
      final fin = inicio.add(const Duration(hours: 1));
      tendencia.add(_totalVentasEnRango(movimientos, inicio, fin));
    }
    return tendencia;
  }

  /// Tendencia diaria: ventas por día de los últimos N días.
  List<double> _tendenciaPorDias(
    List<Movimiento> movimientos,
    DateTime now,
    int dias,
  ) {
    final tendencia = <double>[];
    for (int i = dias - 1; i >= 0; i--) {
      final dia = now.subtract(Duration(days: i));
      final inicio = DateTime(dia.year, dia.month, dia.day);
      final fin = inicio.add(const Duration(days: 1));
      tendencia.add(_totalVentasEnRango(movimientos, inicio, fin));
    }
    return tendencia;
  }

  double _totalVentasEnRango(
    List<Movimiento> movimientos,
    DateTime inicio,
    DateTime fin,
  ) {
    return movimientos
        .where((m) {
          return m.tipo == MovimientoTipo.salida &&
              m.ventaId != null &&
              m.fecha.isAfter(inicio.subtract(const Duration(milliseconds: 1))) &&
              m.fecha.isBefore(fin);
        })
        .fold<double>(
          0.0,
          (sum, m) => sum + (m.precioUnitario ?? 0.0) * m.cantidad,
        );
  }
}

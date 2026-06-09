import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/categoria.dart';
import '../../../shared/models/movimiento.dart';
import '../../../shared/models/producto.dart';
import '../data/producto_repository.dart';

final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return InMemoryProductoRepository();
});

final inventarioControllerProvider =
    NotifierProvider<InventarioController, InventarioState>(
      InventarioController.new,
    );

class InventarioState {
  const InventarioState({
    required this.productos,
    required this.categorias,
    this.search = '',
    this.categoriaId,
  });

  final List<Producto> productos;
  final List<Categoria> categorias;
  final String search;
  final String? categoriaId;

  List<Producto> get productosFiltrados {
    final normalizedSearch = search.trim().toLowerCase();
    return productos.where((producto) {
      final matchesSearch =
          normalizedSearch.isEmpty ||
          producto.nombre.toLowerCase().contains(normalizedSearch) ||
          (producto.codigoRef ?? '').toLowerCase().contains(normalizedSearch);
      final matchesCategoria =
          categoriaId == null || producto.categoriaId == categoriaId;
      return producto.activo && matchesSearch && matchesCategoria;
    }).toList();
  }

  int get totalProductos =>
      productos.where((producto) => producto.activo).length;

  double get valorTotal {
    return productos
        .where((producto) => producto.activo)
        .fold(0, (total, producto) => total + producto.valorTotal);
  }

  InventarioState copyWith({
    List<Producto>? productos,
    List<Categoria>? categorias,
    String? search,
    String? categoriaId,
    bool clearCategoria = false,
  }) {
    return InventarioState(
      productos: productos ?? this.productos,
      categorias: categorias ?? this.categorias,
      search: search ?? this.search,
      categoriaId: clearCategoria ? null : categoriaId ?? this.categoriaId,
    );
  }
}

class InventarioController extends Notifier<InventarioState> {
  ProductoRepository get _repository => ref.read(productoRepositoryProvider);

  @override
  InventarioState build() {
    return InventarioState(
      productos: _repository.fetchProductos(),
      categorias: _repository.fetchCategorias(),
    );
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  void setCategoria(String? categoriaId) {
    state = state.copyWith(
      categoriaId: categoriaId,
      clearCategoria: categoriaId == null,
    );
  }

  Producto? findProducto(String id) {
    final index = state.productos.indexWhere((producto) => producto.id == id);
    if (index == -1) {
      return null;
    }
    return state.productos[index];
  }

  void upsertProducto(Producto producto) {
    _repository.upsertProducto(producto);
    _refresh();
  }

  void deleteProducto(String id) {
    _repository.deleteProducto(id);
    _refresh();
  }

  void applyMovimiento({
    required String productoId,
    required MovimientoTipo tipo,
    required int cantidad,
  }) {
    final producto = _repository.findProducto(productoId);
    if (producto == null) {
      return;
    }

    final signedQuantity = tipo == MovimientoTipo.entrada
        ? cantidad
        : -cantidad;
    final nextStock = (producto.stockActual + signedQuantity).clamp(0, 999999);

    _repository.upsertProducto(
      producto.copyWith(stockActual: nextStock, updatedAt: DateTime.now()),
    );
    _refresh();
  }

  void upsertCategoria(Categoria categoria) {
    _repository.upsertCategoria(categoria);
    _refresh();
  }

  void deleteCategoria(String id) {
    _repository.deleteCategoria(id);
    _refresh();
  }

  /// Devuelve stock de [productoId] en [cantidad] unidades.
  /// Inverso de [applyMovimiento] para salidas.
  void restoreMovimiento({
    required String productoId,
    required int cantidad,
  }) {
    final producto = _repository.findProducto(productoId);
    if (producto == null) return;

    final nextStock =
        (producto.stockActual + cantidad).clamp(0, 999999);
    _repository.upsertProducto(
      producto.copyWith(
        stockActual: nextStock,
        updatedAt: DateTime.now(),
      ),
    );
    _refresh();
  }

  bool existsProductoConNombre(String nombre, {String? excludeId}) {
    final normalized = nombre.trim().toLowerCase();
    return state.productos.any(
      (p) =>
          p.activo &&
          p.nombre.trim().toLowerCase() == normalized &&
          p.id != excludeId,
    );
  }

  bool existsCategoriaConNombre(String nombre, {String? excludeId}) {
    return _repository.existsCategoriaConNombre(nombre, excludeId: excludeId);
  }

  void _refresh() {
    state = state.copyWith(
      productos: _repository.fetchProductos(),
      categorias: _repository.fetchCategorias(),
    );
  }
}

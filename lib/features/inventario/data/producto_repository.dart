import '../../../shared/models/categoria.dart';
import '../../../shared/models/producto.dart';
import 'categoria_repository.dart';

abstract class ProductoRepository implements CategoriaRepository {
  List<Producto> fetchProductos();
  Producto? findProducto(String id);
  void upsertProducto(Producto producto);
  void deleteProducto(String id);
}

List<Categoria> demoCategorias() {
  return [
    Categoria(
      id: 'cat-cascos',
      nombre: 'Cascos',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-repuestos',
      nombre: 'Repuestos',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-accesorios',
      nombre: 'Accesorios',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-lubricantes',
      nombre: 'Lubricantes',
      createdAt: DateTime(2026, 6, 1),
    ),
  ];
}

List<Producto> demoProductos() {
  return [
    Producto(
      id: 'prod-casco',
      nombre: 'Casco Integral Shoei GT-Air II',
      categoriaId: 'cat-cascos',
      categoriaNombre: 'Cascos',
      precio: 450,
      stockActual: 8,
      stockMinimo: 3,
      codigoRef: 'CAS-001',
      fotoUrl: 'assets/images/casco.jpg',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-cadena',
      nombre: 'Kit de Cadena 520 DID',
      categoriaId: 'cat-repuestos',
      categoriaNombre: 'Repuestos',
      precio: 65,
      stockActual: 18,
      stockMinimo: 3,
      codigoRef: 'REP-002',
      fotoUrl: 'assets/images/cadena.jpg',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-guantes',
      nombre: 'Guantes Alpinestars SP-8',
      categoriaId: 'cat-accesorios',
      categoriaNombre: 'Accesorios',
      precio: 85,
      stockActual: 12,
      stockMinimo: 3,
      codigoRef: 'ACC-003',
      fotoUrl: 'assets/images/guantes.jpg',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-aceite',
      nombre: 'Aceite Motul 5100 10W-40',
      categoriaId: 'cat-lubricantes',
      categoriaNombre: 'Lubricantes',
      precio: 35,
      stockActual: 25,
      stockMinimo: 5,
      codigoRef: 'LUB-004',
      fotoUrl: 'assets/images/aceite.jpg',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-cubre-tanque',
      nombre: 'Cubre Tanque Universal',
      categoriaId: 'cat-accesorios',
      categoriaNombre: 'Accesorios',
      precio: 28,
      stockActual: 20,
      stockMinimo: 3,
      codigoRef: 'ACC-005',
      fotoUrl: 'assets/images/cubre-tanque.jpg',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
  ];
}

class InMemoryProductoRepository implements ProductoRepository {
  InMemoryProductoRepository()
    : _categorias = demoCategorias(),
      _productos = demoProductos();

  final List<Categoria> _categorias;
  final List<Producto> _productos;

  @override
  List<Categoria> fetchCategorias() {
    return List.unmodifiable(_categorias);
  }

  @override
  List<Producto> fetchProductos() {
    return List.unmodifiable(_productos.map(_withCategoryName));
  }

  @override
  Producto? findProducto(String id) {
    final index = _productos.indexWhere((producto) => producto.id == id);
    if (index == -1) {
      return null;
    }

    return _withCategoryName(_productos[index]);
  }

  @override
  void upsertProducto(Producto producto) {
    final index = _productos.indexWhere((item) => item.id == producto.id);
    final normalized = producto.copyWith(updatedAt: DateTime.now());

    if (index == -1) {
      _productos.insert(0, normalized);
    } else {
      _productos[index] = normalized;
    }
  }

  @override
  void deleteProducto(String id) {
    final index = _productos.indexWhere((producto) => producto.id == id);
    if (index != -1) {
      _productos[index] = _productos[index].copyWith(
        activo: false,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  void upsertCategoria(Categoria categoria) {
    final index = _categorias.indexWhere((item) => item.id == categoria.id);
    if (index == -1) {
      _categorias.add(categoria);
    } else {
      _categorias[index] = categoria;
    }
  }

  @override
  void deleteCategoria(String id) {
    _categorias.removeWhere((categoria) => categoria.id == id);
  }

  @override
  bool existsCategoriaConNombre(String nombre, {String? excludeId}) {
    final normalized = nombre.trim().toLowerCase();
    return _categorias.any(
      (c) => c.nombre.trim().toLowerCase() == normalized && c.id != excludeId,
    );
  }

  Producto _withCategoryName(Producto producto) {
    final index = _categorias.indexWhere(
      (categoria) => categoria.id == producto.categoriaId,
    );

    return producto.copyWith(
      categoriaNombre: index == -1
          ? 'Sin categoría'
          : _categorias[index].nombre,
    );
  }
}

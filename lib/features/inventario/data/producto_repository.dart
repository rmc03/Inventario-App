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
      id: 'cat-computadoras',
      nombre: 'Computadoras',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-perifericos',
      nombre: 'Periféricos',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-muebles',
      nombre: 'Muebles',
      createdAt: DateTime(2026, 6, 1),
    ),
  ];
}

List<Producto> demoProductos() {
  return [
    Producto(
      id: 'prod-laptop',
      nombre: 'Laptop Dell Inspiron 15',
      categoriaId: 'cat-computadoras',
      categoriaNombre: 'Computadoras',
      precio: 750,
      stockActual: 15,
      stockMinimo: 3,
      codigoRef: 'LAP-001',
      fotoUrl:
          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=400&q=80',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-keyboard',
      nombre: 'Teclado Inalámbrico Logitech',
      categoriaId: 'cat-perifericos',
      categoriaNombre: 'Periféricos',
      precio: 45,
      stockActual: 30,
      stockMinimo: 3,
      codigoRef: 'TEC-002',
      fotoUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-mouse',
      nombre: 'Mouse Óptico HP',
      categoriaId: 'cat-perifericos',
      categoriaNombre: 'Periféricos',
      precio: 18,
      stockActual: 4,
      stockMinimo: 3,
      codigoRef: 'MOU-003',
      fotoUrl:
          'https://images.unsplash.com/photo-1527814050087-3793815479db?auto=format&fit=crop&w=400&q=80',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-monitor',
      nombre: 'Monitor 24" Samsung',
      categoriaId: 'cat-computadoras',
      categoriaNombre: 'Computadoras',
      precio: 150,
      stockActual: 12,
      stockMinimo: 3,
      codigoRef: 'MON-004',
      fotoUrl:
          'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?auto=format&fit=crop&w=400&q=80',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-chair',
      nombre: 'Silla Ergonómica',
      categoriaId: 'cat-muebles',
      categoriaNombre: 'Muebles',
      precio: 120,
      stockActual: 8,
      stockMinimo: 3,
      codigoRef: 'SIL-005',
      fotoUrl:
          'https://images.unsplash.com/photo-1580480055273-228ff5388ef8?auto=format&fit=crop&w=400&q=80',
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

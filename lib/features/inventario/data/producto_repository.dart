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
      id: 'cat-alimentos',
      nombre: 'Alimentos',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-bebidas',
      nombre: 'Bebidas',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-limpieza',
      nombre: 'Limpieza',
      createdAt: DateTime(2026, 6, 1),
    ),
    Categoria(
      id: 'cat-otros',
      nombre: 'Otros',
      createdAt: DateTime(2026, 6, 1),
    ),
  ];
}

List<Producto> demoProductos() {
  return [
    Producto(
      id: 'prod-aceite',
      nombre: 'Aceite de Girasol 900 Ml',
      categoriaId: 'cat-alimentos',
      categoriaNombre: 'Alimentos',
      precio: 1600,
      stockActual: 45,
      stockMinimo: 10,
      codigoRef: 'ALI-001',
      fotoUrl: 'assets/images/aceite.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 20, 9),
    ),
    Producto(
      id: 'prod-arroz',
      nombre: 'Bolsa de Arroz Importado 1 Kg',
      categoriaId: 'cat-alimentos',
      categoriaNombre: 'Alimentos',
      precio: 650,
      stockActual: 67,
      stockMinimo: 15,
      codigoRef: 'ALI-002',
      fotoUrl: 'assets/images/arroz.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 18, 9),
    ),
    Producto(
      id: 'prod-cafe',
      nombre: 'Café Cubita',
      categoriaId: 'cat-bebidas',
      categoriaNombre: 'Bebidas',
      precio: 2000,
      stockActual: 20,
      stockMinimo: 5,
      codigoRef: 'BEB-001',
      fotoUrl: 'assets/images/cafe.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 6, 1, 9),
    ),
    Producto(
      id: 'prod-cerveza',
      nombre: 'Cerveza La Fría',
      categoriaId: 'cat-bebidas',
      categoriaNombre: 'Bebidas',
      precio: 280,
      stockActual: 48,
      stockMinimo: 12,
      codigoRef: 'BEB-002',
      fotoUrl: 'assets/images/cerveza.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 15, 14),
    ),
    Producto(
      id: 'prod-detergente',
      nombre: 'Detergente 500 Mg',
      categoriaId: 'cat-limpieza',
      categoriaNombre: 'Limpieza',
      precio: 500,
      stockActual: 54,
      stockMinimo: 10,
      codigoRef: 'LIM-001',
      fotoUrl: 'assets/images/detergente.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 21, 9, 30),
    ),
    Producto(
      id: 'prod-frijoles',
      nombre: 'Frijoles Importados 1 Kg',
      categoriaId: 'cat-alimentos',
      categoriaNombre: 'Alimentos',
      precio: 850,
      stockActual: 38,
      stockMinimo: 8,
      codigoRef: 'ALI-003',
      fotoUrl: 'assets/images/frijoles.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 10, 10),
    ),
    Producto(
      id: 'prod-huevos',
      nombre: 'File de Huevos',
      categoriaId: 'cat-alimentos',
      categoriaNombre: 'Alimentos',
      precio: 2700,
      stockActual: 15,
      stockMinimo: 5,
      codigoRef: 'ALI-004',
      fotoUrl: 'assets/images/huevo.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 8, 11),
    ),
    Producto(
      id: 'prod-jabon',
      nombre: 'Jabón Suchel 180 Mg',
      categoriaId: 'cat-limpieza',
      categoriaNombre: 'Limpieza',
      precio: 200,
      stockActual: 85,
      stockMinimo: 20,
      codigoRef: 'LIM-002',
      fotoUrl: 'assets/images/jabon.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 20, 11),
    ),
    Producto(
      id: 'prod-pollo',
      nombre: 'Muslo de Pollo 2 Kg',
      categoriaId: 'cat-alimentos',
      categoriaNombre: 'Alimentos',
      precio: 2200,
      stockActual: 22,
      stockMinimo: 8,
      codigoRef: 'ALI-005',
      fotoUrl: 'assets/images/pollo.png',
      createdAt: DateTime(2026, 6, 1, 9),
      updatedAt: DateTime(2026, 7, 16, 15),
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

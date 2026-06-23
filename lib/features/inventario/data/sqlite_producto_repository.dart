import '../../../core/local_db/local_database.dart';
import '../../../shared/models/categoria.dart';
import '../../../shared/models/producto.dart';
import 'producto_repository.dart';

class SqliteProductoRepository implements ProductoRepository {
  SqliteProductoRepository(this._db);

  final LocalDatabase _db;

  // ─── Categorías ────────────────────────────────────────────────────────────

  static const _catTable = 'categorias';

  @override
  List<Categoria> fetchCategorias() {
    // Synchronous wrapper: we cache in-memory after first async load.
    if (_cachedCategorias.isEmpty) {
      return List.unmodifiable(demoCategorias());
    }
    return List.unmodifiable(_cachedCategorias);
  }

  List<Categoria> _cachedCategorias = [];

  Future<void> ensureLoaded() async {
    final db = await _db.database;
    final rows = await db.query(_catTable, orderBy: 'nombre ASC');
    _cachedCategorias = rows.map((r) => Categoria.fromLocalMap(r)).toList();
  }

  @override
  void upsertCategoria(Categoria categoria) {
    final db = _db.database;
    db.then((d) async {
      final existing = await d.query(
        _catTable,
        where: 'id = ?',
        whereArgs: [categoria.id],
      );
      if (existing.isEmpty) {
        await d.insert(_catTable, categoria.toLocalMap());
      } else {
        await d.update(
          _catTable,
          categoria.toLocalMap(),
          where: 'id = ?',
          whereArgs: [categoria.id],
        );
      }
      await _reloadCategorias(d);
    });
  }

  @override
  void deleteCategoria(String id) {
    _db.database.then((d) async {
      await d.delete(_catTable, where: 'id = ?', whereArgs: [id]);
      await _reloadCategorias(d);
    });
  }

  @override
  bool existsCategoriaConNombre(String nombre, {String? excludeId}) {
    final normalized = nombre.trim().toLowerCase();
    return _cachedCategorias.any(
      (c) => c.nombre.trim().toLowerCase() == normalized && c.id != excludeId,
    );
  }

  Future<void> _reloadCategorias(dynamic d) async {
    final rows = await d.query(_catTable, orderBy: 'nombre ASC');
    _cachedCategorias = rows.map((r) => Categoria.fromLocalMap(r)).toList();
  }

  // ─── Productos ─────────────────────────────────────────────────────────────

  List<Producto> _cachedProductos = [];

  Future<void> ensureProductosLoaded() async {
    final db = await _db.database;
    final rows = await db.query('productos', orderBy: 'created_at DESC');
    _cachedProductos = rows
        .map((r) => _withCategoryName(Producto.fromLocalMap(r)))
        .toList();
  }

  @override
  List<Producto> fetchProductos() {
    if (_cachedProductos.isEmpty) {
      return List.unmodifiable(demoProductos());
    }
    return List.unmodifiable(_cachedProductos);
  }

  @override
  Producto? findProducto(String id) {
    final productos = _cachedProductos.isEmpty
        ? demoProductos()
        : _cachedProductos;
    final index = productos.indexWhere((p) => p.id == id);
    if (index == -1) return null;
    return productos[index];
  }

  @override
  void upsertProducto(Producto producto) {
    final normalized = producto.copyWith(updatedAt: DateTime.now());
    _db.database.then((d) async {
      final existing = await d.query(
        'productos',
        where: 'id = ?',
        whereArgs: [normalized.id],
      );
      final map = normalized.toLocalMap()
        ..['activo'] = normalized.activo ? 1 : 0;
      if (existing.isEmpty) {
        await d.insert('productos', map);
      } else {
        await d.update(
          'productos',
          map,
          where: 'id = ?',
          whereArgs: [normalized.id],
        );
      }
      await _reloadProductos(d);
    });
  }

  @override
  void deleteProducto(String id) {
    _db.database.then((d) async {
      await d.update(
        'productos',
        {'activo': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _reloadProductos(d);
    });
  }

  Future<void> _reloadProductos(dynamic d) async {
    final rows = await d.query('productos', orderBy: 'created_at DESC');
    _cachedProductos = rows
        .map((r) => _withCategoryName(Producto.fromLocalMap(r)))
        .toList();
  }

  Producto _withCategoryName(Producto producto) {
    final index = _cachedCategorias.indexWhere(
      (c) => c.id == producto.categoriaId,
    );
    return producto.copyWith(
      categoriaNombre: index == -1
          ? 'Sin categoría'
          : _cachedCategorias[index].nombre,
    );
  }
}

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'inventario_app.db'),
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE productos (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  categoria_id TEXT NOT NULL,
  categoria_nombre TEXT,
  precio REAL NOT NULL DEFAULT 0,
  stock_actual INTEGER NOT NULL DEFAULT 0,
  stock_minimo INTEGER NOT NULL DEFAULT 3,
  codigo_ref TEXT,
  foto_url TEXT,
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE categorias (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE movimientos (
  id TEXT PRIMARY KEY,
  producto_id TEXT NOT NULL,
  producto_nombre TEXT NOT NULL,
  usuario_id TEXT NOT NULL,
  usuario_nombre TEXT NOT NULL,
  usuario_foto_url TEXT,
  tipo TEXT NOT NULL,
  cantidad INTEGER NOT NULL,
  nota TEXT,
  fecha TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE cuadres (
  id TEXT PRIMARY KEY,
  dependiente_id TEXT NOT NULL,
  dependiente_nombre TEXT NOT NULL,
  dependiente_foto_url TEXT,
  fecha_turno TEXT NOT NULL,
  total_entradas INTEGER NOT NULL DEFAULT 0,
  total_salidas INTEGER NOT NULL DEFAULT 0,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  comentario_jefe TEXT,
  items_json TEXT,
  synced INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE usuarios (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  nombre TEXT NOT NULL,
  rol TEXT NOT NULL,
  foto_url TEXT,
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''');
        // indexes
        await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_movimientos_producto_fecha ON movimientos(producto_id, fecha);
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE productos ADD COLUMN descripcion TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
CREATE TABLE IF NOT EXISTS categorias (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
          await db.execute('ALTER TABLE cuadres ADD COLUMN items_json TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(
            "UPDATE productos SET stock_minimo = 3 WHERE stock_minimo = 0 OR stock_minimo IS NULL",
          );
        }
        if (oldVersion < 5) {
          await db.execute('''
CREATE TABLE IF NOT EXISTS usuarios (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  nombre TEXT NOT NULL,
  rol TEXT NOT NULL,
  foto_url TEXT,
  activo INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''');
          // Add photo columns if not present
          try {
            await db.execute('ALTER TABLE movimientos ADD COLUMN usuario_foto_url TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE cuadres ADD COLUMN dependiente_foto_url TEXT');
          } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute('CREATE INDEX IF NOT EXISTS idx_movimientos_producto_fecha ON movimientos(producto_id, fecha)');
          } catch (_) {}
        }
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE cuadres ADD COLUMN ventas_json TEXT');
          } catch (_) {}
        }
      },
    );

    _database = database;
    return database;
  }

  /// Directory for app-local files. Uses the database path as a base
  /// to avoid adding `path_provider` as a dependency.
  Future<Directory> get appDocsDir async {
    final dbPath = await getDatabasesPath();
    final dir = Directory(p.join(dbPath, 'inventario_files'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

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
      version: 4,
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
      },
    );

    _database = database;
    return database;
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/local_db/local_database.dart';
import 'package:inventario_app/features/movimientos/data/sqlite_movimiento_repository.dart';
import 'package:inventario_app/shared/models/movimiento.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Bug Condition Exploration Test
/// 
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4**
/// 
/// **Property 1: Bug Condition** - Movimientos persisten en SQLite entre sesiones
/// 
/// **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
/// **DO NOT attempt to fix the test or the code when it fails**
/// 
/// This test encodes the EXPECTED behavior (movimientos should NOT persist).
/// When run against SqliteMovimientoRepository (the buggy implementation),
/// it will FAIL because movimientos DO persist (proving the bug exists).
/// When run against InMemoryMovimientoRepository (the fix), it will PASS.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Bug Condition Exploration - Movimientos Persistence', () {
    late Database testDb;
    late SqliteMovimientoRepository repository;

    setUp(() async {
      // Create a fresh in-memory SQLite database for each test
      testDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create the movimientos table
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
  venta_id TEXT,
  precio_unitario REAL,
  synced INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');
          },
        ),
      );
      
      // Create a test LocalDatabase wrapper
      final testLocalDb = _TestLocalDatabase(testDb);
      repository = SqliteMovimientoRepository(testLocalDb);
    });

    tearDown(() async {
      repository.dispose();
      await testDb.close();
    });

    test(
      'EXPECTED: After restart, movimientos should reset to initial demo data (30 movimientos)',
      () async {
        // ── Session 1: Initial state ──
        await repository.ensureLoaded();
        
        // Verify initial state has 0 movimientos (fresh DB, no seeding)
        final initialMovimientos = repository.fetchMovimientos();
        expect(initialMovimientos.length, 0, 
          reason: 'Fresh SQLite database should be empty');

        // Simulate creating 2 movimientos in the current session
        const uuid = Uuid();
        final movimiento1 = Movimiento(
          id: uuid.v4(),
          productoId: 'prod-test-1',
          productoNombre: 'Producto Test 1',
          usuarioId: 'user-test',
          usuarioNombre: 'Usuario Test',
          tipo: MovimientoTipo.salida,
          cantidad: 5,
          fecha: DateTime.now(),
          synced: false,
          createdAt: DateTime.now(),
        );
        
        final movimiento2 = Movimiento(
          id: uuid.v4(),
          productoId: 'prod-test-2',
          productoNombre: 'Producto Test 2',
          usuarioId: 'user-test',
          usuarioNombre: 'Usuario Test',
          tipo: MovimientoTipo.entrada,
          cantidad: 10,
          fecha: DateTime.now(),
          synced: false,
          createdAt: DateTime.now(),
        );

        repository.addMovimiento(movimiento1);
        repository.addMovimiento(movimiento2);

        // Wait for async operations to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify movimientos were added
        final afterAdd = repository.fetchMovimientos();
        expect(afterAdd.length, 2, 
          reason: 'Should have 2 movimientos after adding');

        // ── Simulate App Restart (Session 2) ──
        // Dispose current repository and create a new one with the SAME database
        repository.dispose();
        
        // Create new repository instance (simulating app restart)
        final testLocalDb2 = _TestLocalDatabase(testDb);
        final repository2 = SqliteMovimientoRepository(testLocalDb2);
        await repository2.ensureLoaded();

        // ── EXPECTED BEHAVIOR (encodes the fix) ──
        // After restart, movimientos should reset to initial demo data
        // For a fresh test without seeding, this means 0 movimientos
        // 
        // ⚠️ THIS TEST WILL FAIL with SqliteMovimientoRepository because:
        // - SqliteMovimientoRepository persists data in SQLite
        // - The 2 movimientos created in session 1 will still be present
        // - This PROVES THE BUG EXISTS
        //
        // ✅ This test will PASS with InMemoryMovimientoRepository because:
        // - InMemoryMovimientoRepository stores data only in memory
        // - Creating a new instance resets to initial demo data
        // - This VALIDATES THE FIX
        final afterRestart = repository2.fetchMovimientos();
        expect(afterRestart.length, 0,
          reason: 'After restart, movimientos should reset to initial state. '
                  'Found ${afterRestart.length} movimientos instead. '
                  'This proves the bug: movimientos persisted across sessions when they should not have.');

        repository2.dispose();
      },
    );

    test(
      'EXPECTED: Movimientos created in previous sessions should NOT be present after restart',
      () async {
        // ── Session 1 ──
        await repository.ensureLoaded();
        
        const uuid = Uuid();
        
        // Create 3 movimientos in session 1
        for (int i = 0; i < 3; i++) {
          final movimiento = Movimiento(
            id: uuid.v4(),
            productoId: 'prod-session1-$i',
            productoNombre: 'Producto Session 1 - $i',
            usuarioId: 'user-test',
            usuarioNombre: 'Usuario Test',
            tipo: MovimientoTipo.salida,
            cantidad: i + 1,
            fecha: DateTime.now(),
            synced: false,
            createdAt: DateTime.now(),
          );
          repository.addMovimiento(movimiento);
        }

        await Future.delayed(const Duration(milliseconds: 100));
        expect(repository.fetchMovimientos().length, 3);

        // ── Restart to Session 2 ──
        repository.dispose();
        final testLocalDb2 = _TestLocalDatabase(testDb);
        final repository2 = SqliteMovimientoRepository(testLocalDb2);
        await repository2.ensureLoaded();

        // Create 2 more movimientos in session 2
        for (int i = 0; i < 2; i++) {
          final movimiento = Movimiento(
            id: uuid.v4(),
            productoId: 'prod-session2-$i',
            productoNombre: 'Producto Session 2 - $i',
            usuarioId: 'user-test',
            usuarioNombre: 'Usuario Test',
            tipo: MovimientoTipo.entrada,
            cantidad: i + 1,
            fecha: DateTime.now(),
            synced: false,
            createdAt: DateTime.now(),
          );
          repository2.addMovimiento(movimiento);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // ── Restart to Session 3 ──
        repository2.dispose();
        final testLocalDb3 = _TestLocalDatabase(testDb);
        final repository3 = SqliteMovimientoRepository(testLocalDb3);
        await repository3.ensureLoaded();

        // ── EXPECTED BEHAVIOR ──
        // After restart, should have 0 movimientos (reset to initial state)
        // 
        // ⚠️ BUG: With SqliteMovimientoRepository, we'll have 5 movimientos (3 + 2)
        // because all movimientos from previous sessions persisted in SQLite
        final movimientos = repository3.fetchMovimientos();
        expect(movimientos.length, 0,
          reason: 'After restart, all movimientos from previous sessions should be discarded. '
                  'Found ${movimientos.length} movimientos (accumulated from previous sessions). '
                  'This demonstrates the bug: data accumulation across sessions.');

        repository3.dispose();
      },
    );

    test(
      'EXPECTED: System should use ephemeral storage, not persist to SQLite',
      () async {
        // This test verifies the system behavior at a conceptual level
        // ── Session 1 ──
        await repository.ensureLoaded();
        
        const uuid = Uuid();
        final movimiento = Movimiento(
          id: uuid.v4(),
          productoId: 'prod-ephemeral-test',
          productoNombre: 'Producto Ephemeral Test',
          usuarioId: 'user-test',
          usuarioNombre: 'Usuario Test',
          tipo: MovimientoTipo.salida,
          cantidad: 7,
          fecha: DateTime.now(),
          synced: false,
          createdAt: DateTime.now(),
        );

        repository.addMovimiento(movimiento);
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify movimiento was added to current session
        final beforeRestart = repository.fetchMovimientos();
        expect(beforeRestart.length, 1);
        expect(beforeRestart.first.productoNombre, 'Producto Ephemeral Test');

        // ── Simulate App Restart ──
        repository.dispose();
        final testLocalDb2 = _TestLocalDatabase(testDb);
        final repository2 = SqliteMovimientoRepository(testLocalDb2);
        await repository2.ensureLoaded();

        // ── EXPECTED: Data should be ephemeral (not persisted) ──
        // 
        // ⚠️ BUG CONDITION: SqliteMovimientoRepository persists to SQLite,
        // so the movimiento will still be present after restart.
        // This test FAILS, proving movimientos are NOT ephemeral.
        //
        // ✅ FIX: InMemoryMovimientoRepository stores in memory only,
        // so data is truly ephemeral and resets on restart.
        final afterRestart = repository2.fetchMovimientos();
        expect(afterRestart, isEmpty,
          reason: 'Movimientos should be ephemeral (exist only in current session). '
                  'Found ${afterRestart.length} persisted movimientos. '
                  'This confirms the bug: data is persisted in SQLite instead of being ephemeral.');

        repository2.dispose();
      },
    );
  });
}

/// Test wrapper for LocalDatabase that mimics its interface
class _TestLocalDatabase implements LocalDatabase {
  _TestLocalDatabase(this._db);
  final Database _db;
  
  @override
  Future<Database> get database async => _db;
  
  @override
  Future<Directory> get appDocsDir async => throw UnimplementedError('Not needed for tests');
}

# 📦 Inventario App — Arquitectura del Proyecto

> Aplicación móvil de gestión de inventario y punto de venta (POS) para tiendas retail locales.
> Stack: Flutter + Riverpod + go_router + sqflite + Supabase (preparado pero no conectado por defecto).
> Distribución interna (APK directa, sin Play Store).

---

## 1. Resumen General

| Elemento | Detalle |
|---|---|
| **Framework** | Flutter (Dart) |
| **Backend remoto** | Supabase (Auth + PostgreSQL + Storage) — preparado, desconectado por defecto |
| **Base de datos local** | sqflite (SQLite) para usuarios y movimientos |
| **Datos temporales** | En memoria (productos, categorías, ventas, cuadres, turno) |
| **Estado** | flutter_riverpod |
| **Navegación** | go_router con redirección por rol |
| **Usuarios** | 2 roles: Admin y Dependiente |
| **Distribución** | APK directa desde Android Studio |

> **Nota de implementación:** A junio de 2026 la app funciona como prototrollo offline-first. La sincronización con Supabase existe como esqueleto (`SyncService`, `supabaseClientProvider`) pero no está operativa. Ver [Estado de implementación](#13-estado-de-implementación).

---

## 2. Roles y Permisos

### 2.1 Admin (Jefe)
- CRUD completo de productos y categorías.
- Ver historial de movimientos general, filtrado por tipo y agrupado por producto o por venta.
- Ver, aprobar o rechazar cuadres de turno.
- Gestionar usuarios dependientes (crear, editar, desactivar).

### 2.2 Dependiente
- Iniciar y cerrar turno.
- Registrar ventas POS (selección de productos, cantidades, carrito, pago).
- Ver inventario en solo lectura.
- Ver historial de ventas del turno actual y enviar cuadre.

> **Nota de sesión:** La autenticación es simulada localmente. El login presenta un selector de rol y asigna un usuario fijo de demostración. La sesión se mantiene en memoria de Riverpod mientras la app esté abierta.

---

## 3. Navegación por Rol

```
LoginScreen (/login)
  └── (verifica sesión)
        ├── Sin sesión → LoginScreen
        └── Con sesión
              ├── rol = admin  → AdminShell
              └── rol = dependiente → DependienteShell

AdminShell (RoleShell)
  ├── /admin/inventario                          → InventarioScreen (CRUD)
  ├── /admin/inventario/productos/nuevo          → ProductoFormScreen (crear)
  ├── /admin/inventario/productos/:id            → ProductoDetalleScreen
  ├── /admin/inventario/productos/:id/editar     → ProductoFormScreen (editar)
  ├── /admin/movimientos                         → MovimientosScreen
  ├── /admin/cuadres                             → CuadresScreen (panel de aprobación)
  ├── /admin/cuadres/:id                         → CuadreDetalleScreen
  └── /admin/configuracion                       → ConfiguracionScreen

DependienteShell (RoleShell)
  ├── /dependiente/turno                         → MiTurnoScreen
  ├── /dependiente/turno/resumen                 → CuadreResumenScreen
  ├── /dependiente/turno/nueva-venta             → NuevaVentaScreen
  ├── /dependiente/turno/confirmar-pago          → ConfirmarPagoScreen
  ├── /dependiente/turno/venta/:id               → VentaDetalleScreen
  ├── /dependiente/inventario                    → InventarioScreen (solo lectura)
  ├── /dependiente/inventario/productos/:id      → ProductoDetalleScreen (solo lectura)
  └── /dependiente/configuracion                 → ConfiguracionScreen
```

---

## 4. Pantallas

### 4.1 LoginScreen
- Selector de rol (Admin / Dependiente).
- Campos de email y contraseña (ilustrativos).
- Al autenticar, redirige según el rol seleccionado.

### 4.2 InventarioScreen
- Lista de productos con búsqueda por nombre.
- Filtro por categoría.
- Ordenamiento por nombre, precio o stock.
- Filtro "Solo stock bajo".
- Indicador visual de stock bajo.
- **Admin:** botón "+" para crear producto; al tocar un producto se abre detalle/editar.
- **Dependiente:** al tocar un producto se abre solo lectura.

### 4.3 ProductoDetalleScreen
- Foto, nombre, descripción, categoría, precio, stock.
- **Admin:** botón de editar y opción de eliminar.

### 4.4 ProductoFormScreen
- Campos: nombre, descripción, categoría, stock, precio, foto.
- Permite crear/editar producto.
- Incluye opción de crear nueva categoría desde el selector.

### 4.5 MovimientosScreen (solo Admin)
- Historial general de movimientos.
- Filtro por tipo (entrada/salida/todos).
- Dos vistas: agrupado por producto o por venta POS.
- Cada movimiento muestra producto, tipo, cantidad, usuario, fecha/hora y nota.

### 4.6 MiTurnoScreen (solo Dependiente)
- Tres estados: sin turno activo, turno activo, cuadre enviado.
- En turno activo: resumen de ventas del día, historial de ventas, botón "Nueva venta".
- Menú para cerrar turno / ver resumen.

### 4.7 NuevaVentaScreen (solo Dependiente)
- Búsqueda y filtrado de productos.
- Selector de cantidad por producto.
- Carrito persistente durante la construcción de la venta.
- Validación de stock disponible.

### 4.8 ConfirmarPagoScreen
- Resumen de ítems de la venta.
- Selección de método de pago: efectivo o transferencia.
- Confirmación que completa la venta.

### 4.9 CuadreResumenScreen (solo Dependiente)
- Resumen de ventas del turno.
- Toggle entre vista por ventas y vista por productos agrupados.
- Botón para enviar cuadre al admin.

### 4.10 CuadresScreen (solo Admin)
- Lista de cuadres ordenados por fecha.
- Badge visual con estado (`pendiente`, `aprobado`, `rechazado`).

### 4.11 CuadreDetalleScreen
- Resumen del cuadre: dependiente, fecha, ventas, totales.
- Toggle entre resumen por venta y productos agrupados.
- Botones para aprobar o rechazar (este último requiere comentario).

### 4.12 ConfiguracionScreen
- Perfil del usuario con foto.
- **Admin:** gestión de dependientes y categorías.
- **Dependiente:** edición de perfil y acceso al resumen del turno activo.

### 4.13 IndicadorConexion
- Banner discreto que aparece solo en modo offline.

---

## 5. Modelos de Datos

Los modelos se encuentran en `lib/shared/models/`.

### 5.1 `Usuario`
```dart
String id
String email
String nombre
UserRole rol     // admin | dependiente
bool activo
String? fotoUrl
DateTime createdAt
```

### 5.2 `Categoria`
```dart
String id
String nombre
DateTime createdAt
```

### 5.3 `Producto`
```dart
String id
String nombre
String? descripcion
String categoriaId
String? categoriaNombre
double precio
int stockActual
int stockMinimo
String? codigoRef
String? fotoUrl
bool activo
DateTime createdAt
DateTime updatedAt
```

### 5.4 `Movimiento`
```dart
String id
String productoId
String productoNombre
String usuarioId
String usuarioNombre
String? usuarioFotoUrl
MovimientoTipo tipo   // entrada | salida
int cantidad
String? nota
DateTime fecha
bool synced
DateTime createdAt
```

### 5.5 `CuadreItem`
```dart
String productoId
String productoNombre
int cantidad
double precioUnitario
```

### 5.6 `Pago`
```dart
MetodoPago metodo   // efectivo | transferencia
double monto
double? efectivoRecibido
```

### 5.7 `Venta`
```dart
String id
String dependienteId
String dependienteNombre
String? dependienteFotoUrl
List<CuadreItem> items
List<Pago> pagos
VentaEstado estado   // enCurso | completada | cancelada
DateTime fecha
bool synced
DateTime createdAt
```

### 5.8 `Cuadre`
```dart
String id
String dependienteId
String dependienteNombre
String? dependienteFotoUrl
DateTime fechaTurno
List<Venta> ventas
CuadreEstado estado   // pendiente | aprobado | rechazado
String? comentarioJefe
DateTime createdAt
DateTime updatedAt
bool synced
```

---

## 6. Schema SQL Objetivo en Supabase

> El siguiente schema representa la estructura objetivo cuando Supabase esté conectado. Actualmente la app usa SQLite local y datos en memoria.

### 6.1 Tabla: `usuarios`
```sql
CREATE TABLE usuarios (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email         text UNIQUE NOT NULL,
  nombre        text NOT NULL,
  rol           text NOT NULL CHECK (rol IN ('admin', 'dependiente')),
  activo        boolean DEFAULT true,
  foto_url      text,
  created_at    timestamptz DEFAULT now()
);
```

### 6.2 Tabla: `categorias`
```sql
CREATE TABLE categorias (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre        text NOT NULL,
  created_at    timestamptz DEFAULT now()
);
```

### 6.3 Tabla: `productos`
```sql
CREATE TABLE productos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre        text NOT NULL,
  descripcion   text,
  categoria_id  uuid REFERENCES categorias(id),
  precio        numeric(10,2) NOT NULL DEFAULT 0,
  stock_actual  integer NOT NULL DEFAULT 0,
  stock_minimo  integer NOT NULL DEFAULT 3,
  codigo_ref    text,
  foto_url      text,
  activo        boolean DEFAULT true,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);
```

### 6.4 Tabla: `movimientos`
```sql
CREATE TABLE movimientos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id   uuid REFERENCES productos(id),
  usuario_id    uuid REFERENCES usuarios(id),
  tipo          text NOT NULL CHECK (tipo IN ('entrada', 'salida')),
  cantidad      integer NOT NULL,
  nota          text,
  fecha         timestamptz DEFAULT now(),
  synced        boolean DEFAULT false,
  created_at    timestamptz DEFAULT now()
);
```

### 6.5 Tabla: `ventas`
```sql
CREATE TABLE ventas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dependiente_id  uuid REFERENCES usuarios(id) NOT NULL,
  estado          text DEFAULT 'completada' CHECK (estado IN ('en_curso', 'completada', 'cancelada')),
  total           numeric(10,2) NOT NULL DEFAULT 0,
  fecha           timestamptz DEFAULT now(),
  synced          boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);
```

### 6.6 Tabla: `venta_items`
```sql
CREATE TABLE venta_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id         uuid REFERENCES ventas(id) ON DELETE CASCADE,
  producto_id      uuid REFERENCES productos(id),
  producto_nombre  text NOT NULL,
  cantidad         integer NOT NULL,
  precio_unitario  numeric(10,2) NOT NULL
);
```

### 6.7 Tabla: `pagos`
```sql
CREATE TABLE pagos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venta_id      uuid REFERENCES ventas(id) ON DELETE CASCADE,
  metodo        text NOT NULL CHECK (metodo IN ('efectivo', 'transferencia')),
  monto         numeric(10,2) NOT NULL,
  efectivo_recibido numeric(10,2),
  created_at    timestamptz DEFAULT now()
);
```

### 6.8 Tabla: `cuadres`
```sql
CREATE TABLE cuadres (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  dependiente_id   uuid REFERENCES usuarios(id) NOT NULL,
  fecha_turno      date NOT NULL,
  total_entradas   integer DEFAULT 0,
  total_salidas    integer DEFAULT 0,
  valor_total      numeric(10,2) DEFAULT 0,
  estado           text DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'aprobado', 'rechazado')),
  comentario_jefe  text,
  synced           boolean DEFAULT false,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);
```

### 6.9 Tabla: `cuadre_ventas`
```sql
CREATE TABLE cuadre_ventas (
  cuadre_id  uuid REFERENCES cuadres(id) ON DELETE CASCADE,
  venta_id   uuid REFERENCES ventas(id) ON DELETE CASCADE,
  PRIMARY KEY (cuadre_id, venta_id)
);
```

---

## 7. Row Level Security (RLS) — Objetivo

```sql
-- Solo el admin puede modificar productos y categorías
CREATE POLICY "admin_productos" ON productos
  USING (auth.jwt() ->> 'rol' = 'admin');

CREATE POLICY "admin_categorias" ON categorias
  USING (auth.jwt() ->> 'rol' = 'admin');

-- Todos los usuarios autenticados pueden leer productos activos
CREATE POLICY "leer_productos" ON productos
  FOR SELECT USING (activo = true AND auth.role() = 'authenticated');

-- Cualquier usuario autenticado puede insertar movimientos y ventas
CREATE POLICY "insertar_movimientos" ON movimientos
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "insertar_ventas" ON ventas
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Admin lee todos los movimientos; dependiente solo los suyos
CREATE POLICY "leer_movimientos" ON movimientos
  FOR SELECT USING (
    auth.jwt() ->> 'rol' = 'admin'
    OR usuario_id = auth.uid()
  );

-- Admin lee todas las ventas; dependiente solo las suyas
CREATE POLICY "leer_ventas" ON ventas
  FOR SELECT USING (
    auth.jwt() ->> 'rol' = 'admin'
    OR dependiente_id = auth.uid()
  );

-- Admin lee y actualiza todos los cuadres; dependiente solo los suyos
CREATE POLICY "admin_cuadres" ON cuadres
  USING (auth.jwt() ->> 'rol' = 'admin');

CREATE POLICY "dependiente_cuadres" ON cuadres
  FOR SELECT USING (dependiente_id = auth.uid());
```

---

## 8. Arquitectura Offline (sqflite + Supabase Sync)

### Flujo de datos objetivo

```
Acción del usuario
  └── Guarda en SQLite local (inmediato, sin importar conexión)
        └── Si hay internet y Supabase configurado → sync automático
              └── Marca registro como synced = true
```

### Tablas locales en SQLite

- `productos` — caché local de productos.
- `categorias` — caché local de categorías.
- `movimientos` — movimientos de inventario (con `synced`).
- `ventas` — ventas completadas (con `synced`).
- `venta_items` — ítems de cada venta.
- `pagos` — pagos asociados a ventas.
- `cuadres` — cuadres de turno (con `synced`).
- `usuarios` — usuarios locales.

### Servicio de sincronización

- Se activa al detectar reconexión a internet (`connectivity_plus`).
- Lee registros locales con `synced = false`.
- Los sube a Supabase en orden cronológico.
- Marca como `synced = true` al confirmar escritura remota.
- Descarga cambios remotos y actualiza el caché local.

> **Estado actual:** `SyncService.syncPending()` solo verifica conectividad y disponibilidad de Supabase; no realiza sync real.

---

## 9. Estructura de Carpetas del Proyecto Flutter

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── app_startup.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_dimens.dart
│   ├── supabase/
│   │   ├── supabase_client.dart
│   │   ├── supabase_config.dart
│   │   └── supabase_bootstrap.dart
│   ├── local_db/
│   │   ├── local_database.dart
│   │   └── sync_service.dart
│   └── utils/
│       ├── connectivity_service.dart
│       └── formatters.dart
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── providers/auth_provider.dart
│   │   └── presentation/login_screen.dart
│   ├── inventario/
│   │   ├── data/
│   │   │   ├── producto_repository.dart
│   │   │   ├── sqlite_producto_repository.dart
│   │   │   └── categoria_repository.dart
│   │   ├── providers/inventario_provider.dart
│   │   └── presentation/
│   │       ├── inventario_screen.dart
│   │       ├── producto_form_screen.dart
│   │       └── producto_detalle_screen.dart
│   ├── movimientos/
│   │   ├── data/
│   │   │   ├── movimiento_repository.dart
│   │   │   └── sqlite_movimiento_repository.dart
│   │   ├── providers/movimiento_provider.dart
│   │   └── presentation/movimientos_screen.dart
│   ├── turno/
│   │   ├── data/turno_repository.dart
│   │   ├── providers/turno_provider.dart
│   │   └── presentation/
│   │       ├── mi_turno_screen.dart
│   │       └── cuadre_resumen_screen.dart
│   ├── cuadres/
│   │   ├── data/
│   │   │   ├── cuadre_repository.dart
│   │   │   └── sqlite_cuadre_repository.dart
│   │   ├── providers/cuadre_provider.dart
│   │   └── presentation/
│   │       ├── cuadres_screen.dart
│   │       └── cuadre_detalle_screen.dart
│   ├── ventas/
│   │   ├── data/venta_repository.dart
│   │   ├── providers/venta_provider.dart
│   │   └── presentation/
│   │       ├── nueva_venta_screen.dart
│   │       ├── confirmar_pago_screen.dart
│   │       └── venta_detalle_screen.dart
│   ├── usuarios/
│   │   ├── data/usuario_repository.dart
│   │   └── providers/usuario_provider.dart
│   └── configuracion/
│       └── presentation/configuracion_screen.dart
└── shared/
    ├── models/
    │   ├── usuario.dart
    │   ├── producto.dart
    │   ├── categoria.dart
    │   ├── movimiento.dart
    │   ├── cuadre.dart
    │   ├── cuadre_item.dart
    │   ├── venta.dart
    │   └── pago.dart
    └── widgets/
        ├── indicador_conexion.dart
        ├── stock_badge.dart
        ├── loading_overlay.dart
        ├── error_page.dart
        ├── product_photo.dart
        ├── qty_controls.dart
        ├── role_shell.dart
        ├── stat_card.dart
        └── category_name_dialog.dart
```

---

## 10. Dependencias Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  supabase_flutter: ^2.14.1
  flutter_riverpod: ^3.3.1
  go_router: ^17.3.0
  sqflite: ^2.4.3
  path: ^1.9.1
  connectivity_plus: ^7.1.1
  cached_network_image: ^3.4.1
  image_picker: ^1.2.2
  uuid: ^4.5.3
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_native_splash: ^2.2.15
```

---

## 11. Variables de Entorno

Las credenciales de Supabase se leen desde variables de entorno al compilar:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key
```

El archivo `lib/core/supabase/supabase_config.dart` las expone así:

```dart
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
```

Si no se configuran, la app arranca en modo demo/offline.

---

## 12. Flujo Completo: Venta POS y Cierre de Turno

```
1. Dependiente abre MiTurnoScreen y presiona "Iniciar turno"
2. App crea el estado de turno activo (memoria)
3. Dependiente va a NuevaVentaScreen
4. Selecciona productos y cantidades (validando stock)
5. Toca "Cobrar" → ConfirmarPagoScreen
6. Selecciona método de pago (efectivo/transferencia)
7. Confirma → VentaEnCursoController.completarVentaConPagos()
8. Por cada ítem:
   - Se descuenta stock en inventario
   - Se crea un movimiento de salida con nota "Venta POS #<id>"
9. La venta se añade al historial del turno
10. Dependiente va a CuadreResumenScreen
11. Revisa ventas y productos, presiona "Confirmar y enviar"
12. CuadreController.crearCuadrePendiente() crea el cuadre en estado pendiente
13. TurnoController.enviarCuadre() marca el turno como cerrado
14. Admin ve el cuadre en CuadresScreen
15. Admin abre CuadreDetalleScreen y:
    - Aprueba: solo cambia estado a aprobado
    - Rechaza: pide comentario, revierte stock con movimientos de entrada y cambia estado a rechazado
```

---

## 13. Estado de Implementación

| Capa | Tecnología actual | Persistencia | Observaciones |
|---|---|---|---|
| Autenticación | `AuthRepository` simulado | SQLite (`usuarios`) | Selector de rol en UI; no valida contra Supabase |
| Productos | `InMemoryProductoRepository` | Memoria | Datos demo; se pierden al cerrar app |
| Categorías | `InMemoryProductoRepository` | Memoria | Datos demo; se pierden al cerrar app |
| Movimientos | `SqliteMovimientoRepository` | SQLite | Persisten localmente |
| Ventas | `VentaRepository` | Memoria | Se pierden al cerrar app |
| Cuadres | `CuadreRepository` | Memoria | Un cuadre demo precargado |
| Turno | `TurnoRepository` | Memoria | Se reinicia al cerrar app |
| Usuarios | `SqliteUsuarioRepository` | SQLite | Persisten localmente |
| Sync | `SyncService` | Ninguna | Placeholder, no realiza sincronización |
| Supabase | `supabase_flutter` | N/A | Desconectado por defecto |

### Próximos pasos técnicos

1. Persistir productos y categorías en SQLite (`SqliteProductoRepository`).
2. Persistir ventas y cuadres en SQLite.
3. Persistir estado del turno en SQLite.
4. Implementar `SyncService` real: cola de cambios, subida ordenada, resolución de conflictos.
5. Conectar autenticación con Supabase Auth.
6. Implementar repositorios remotos para Supabase.
7. Completar tests unitarios y de widgets para el flujo POS.

---

## 14. Consideraciones Finales para el Agente de IA

- Cada `feature` es autónoma: tiene su propio `data/`, `providers/` y `presentation/`.
- Los `repositories` son la única capa que habla con SQLite o Supabase — nunca acceder a la base de datos directamente desde la UI.
- Los `providers` de Riverpod exponen el estado a la UI y llaman a los repositories.
- Todo ID generado offline debe ser un `uuid v4` para evitar conflictos al sincronizar.
- El campo `synced` es la fuente de verdad para saber qué falta por subir a Supabase.
- El modelo `Cuadre` almacena una lista de `Venta`; en el schema objetivo de Supabase se normaliza mediante `cuadre_ventas`.
- Al aprobar un cuadre el stock ya fue descontado durante la venta; al rechazarlo se revierte mediante movimientos de entrada.

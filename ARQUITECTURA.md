# 📦 Inventario App — Arquitectura del Proyecto

> Aplicación móvil de gestión de inventario para tienda retail local.
> Stack: Flutter + Supabase. Distribución interna (APK directa, sin Play Store).

---

## 1. Resumen General

| Elemento | Detalle |
|---|---|
| **Framework** | Flutter (Dart) |
| **Backend** | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| **Offline** | sqflite (SQLite local) con sync automático |
| **Estado** | flutter_riverpod |
| **Navegación** | go_router con redirección por rol |
| **Usuarios** | 2–5 personas (1 Admin/Jefe, 1 Dependiente) |
| **Productos** | ~300 productos |
| **Distribución** | APK directa desde Android Studio |

---

## 2. Roles y Permisos

### 2.1 Admin (Jefe)
- CRUD completo de productos
- Ver historial de movimientos general
- Ver, aprobar o rechazar cuadres de turno
- Gestionar usuarios (crear dependiente, cambiar contraseña)
- Gestionar categorías
- Ver panel de cuadres diarios

### 2.2 Dependiente
- Consultar inventario (solo lectura)
- Registrar entradas y salidas de productos
- Ver historial de movimientos del turno actual ("Mi Turno")
- Cerrar turno y generar cuadre

> **Nota de sesión:** Supabase persiste el token localmente. Ningún usuario necesita hacer login cada vez que abre la app. La sesión se refresca automáticamente en background. Solo se pide login si el usuario cierra sesión manualmente.

---

## 3. Navegación por Rol

```
SplashScreen
  └── (verifica sesión local)
        ├── Sin sesión → LoginScreen
        └── Con sesión
              ├── rol = admin  → AdminShell
              └── rol = dependiente → DependienteShell

AdminShell (Bottom Navigation)
  ├── /admin/inventario         → InventarioScreen
  ├── /admin/movimientos        → MovimientosScreen
  ├── /admin/cuadres            → CuadresScreen (panel de aprobación)
  └── /admin/configuracion      → ConfiguracionScreen

DependienteShell (Bottom Navigation)
  ├── /dependiente/inventario   → InventarioScreen (solo lectura)
  └── /dependiente/turno        → MiTurnoScreen (historial del día + cerrar turno)
```

---

## 4. Pantallas

### 4.1 LoginScreen
- Campo email y contraseña
- Botón "Ingresar"
- Manejo de error (credenciales incorrectas)
- Al autenticar, redirige según `rol` del usuario

---

### 4.2 InventarioScreen (compartida, comportamiento diferente por rol)
- Lista de productos con búsqueda por nombre
- Filtro por categoría
- Indicador visual de stock bajo (cuando `stock_actual <= stock_minimo`)
- Foto del producto si existe
- **Solo Admin:** botón "+" para agregar producto, opciones de editar/eliminar
- **Dependiente:** botón "Registrar movimiento" por producto

#### ProductoFormScreen (solo Admin)
- Campos: nombre, categoría, precio, stock actual, stock mínimo, código de referencia (opcional), foto (Supabase Storage)
- Modo crear y modo editar

---

### 4.3 MovimientosScreen (solo Admin)
- Historial general de todos los movimientos
- Filtro por fecha, por producto, por tipo (entrada/salida)
- Cada ítem muestra: producto, tipo, cantidad, dependiente, fecha/hora, nota

---

### 4.4 MiTurnoScreen (solo Dependiente)
- Lista de movimientos registrados durante el turno actual del día
- Muestra: producto, tipo (entrada/salida), cantidad, hora, nota
- Totales del día: X entradas, X salidas
- Botón **"Cerrar Turno"** al final
  - Genera el cuadre automáticamente con el resumen del día
  - Guarda el cuadre en Supabase con estado `pendiente`
  - Muestra confirmación y bloquea nuevos movimientos hasta el día siguiente

---

### 4.5 CuadresScreen (solo Admin)
- Lista de cuadres ordenados por fecha (más reciente primero)
- Badge visual en los cuadres con estado `pendiente`
- Cada ítem muestra: fecha, dependiente, estado (pendiente / aprobado / rechazado)

#### CuadreDetalleScreen
- Resumen del cuadre: total entradas, total salidas, stock inicial vs final
- Lista de movimientos del turno
- Botón ✅ **Aprobar**
- Botón ❌ **Rechazar** → abre campo de texto para comentario obligatorio
- El estado queda guardado en Supabase con `updated_at` y `comentario_jefe`

---

### 4.6 ConfiguracionScreen (solo Admin)
- Gestión de usuarios: crear dependiente, cambiar contraseña
- Gestión de categorías: crear, editar, eliminar
- Ajuste de stock mínimo global

---

### 4.7 Componente: IndicadorConexion
- Banner o ícono persistente visible en todas las pantallas
- Verde: conectado a internet / sincronizado
- Naranja: modo offline — los datos se guardarán localmente

---

## 5. Schema de Supabase

### 5.1 Tabla: `usuarios`
```sql
id            uuid PRIMARY KEY DEFAULT gen_random_uuid()
email         text UNIQUE NOT NULL
nombre        text NOT NULL
rol           text NOT NULL CHECK (rol IN ('admin', 'dependiente'))
activo        boolean DEFAULT true
created_at    timestamptz DEFAULT now()
```

### 5.2 Tabla: `categorias`
```sql
id            uuid PRIMARY KEY DEFAULT gen_random_uuid()
nombre        text NOT NULL
created_at    timestamptz DEFAULT now()
```

### 5.3 Tabla: `productos`
```sql
id            uuid PRIMARY KEY DEFAULT gen_random_uuid()
nombre        text NOT NULL
categoria_id  uuid REFERENCES categorias(id)
precio        numeric(10,2)
stock_actual  integer NOT NULL DEFAULT 0
stock_minimo  integer NOT NULL DEFAULT 0
codigo_ref    text
foto_url      text
activo        boolean DEFAULT true
created_at    timestamptz DEFAULT now()
updated_at    timestamptz DEFAULT now()
```

### 5.4 Tabla: `movimientos`
```sql
id            uuid PRIMARY KEY DEFAULT gen_random_uuid()
producto_id   uuid REFERENCES productos(id)
usuario_id    uuid REFERENCES usuarios(id)
tipo          text NOT NULL CHECK (tipo IN ('entrada', 'salida'))
cantidad      integer NOT NULL
nota          text
fecha         timestamptz DEFAULT now()
synced        boolean DEFAULT false   -- usado para offline sync
created_at    timestamptz DEFAULT now()
```

### 5.5 Tabla: `cuadres`
```sql
id               uuid PRIMARY KEY DEFAULT gen_random_uuid()
dependiente_id   uuid REFERENCES usuarios(id)
fecha_turno      date NOT NULL
total_entradas   integer DEFAULT 0
total_salidas    integer DEFAULT 0
estado           text DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'aprobado', 'rechazado'))
comentario_jefe  text
created_at       timestamptz DEFAULT now()
updated_at       timestamptz DEFAULT now()
```

---

## 6. Row Level Security (RLS) en Supabase

```sql
-- Solo el admin puede hacer CRUD en productos
CREATE POLICY "admin_productos" ON productos
  USING (auth.jwt() ->> 'rol' = 'admin');

-- Todos los usuarios autenticados pueden leer productos
CREATE POLICY "leer_productos" ON productos
  FOR SELECT USING (auth.role() = 'authenticated');

-- Cualquier usuario autenticado puede insertar movimientos
CREATE POLICY "insertar_movimientos" ON movimientos
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Solo el admin puede leer todos los movimientos
-- El dependiente solo ve los suyos
CREATE POLICY "leer_movimientos" ON movimientos
  FOR SELECT USING (
    auth.jwt() ->> 'rol' = 'admin'
    OR usuario_id = auth.uid()
  );

-- Solo el admin puede leer y actualizar cuadres
CREATE POLICY "admin_cuadres" ON cuadres
  USING (auth.jwt() ->> 'rol' = 'admin');

-- El dependiente solo puede insertar y ver sus propios cuadres
CREATE POLICY "dependiente_cuadres" ON cuadres
  FOR SELECT USING (dependiente_id = auth.uid());
```

---

## 7. Arquitectura Offline (sqflite + Supabase Sync)

### Flujo de datos

```
Acción del usuario
  └── Guarda en SQLite local (inmediato, sin importar conexión)
        └── Si hay internet → sync automático a Supabase
              └── Marca registro como synced = true
```

### Tablas locales en SQLite (espejo de Supabase)
- `productos` — caché local de todos los productos
- `movimientos` — pendientes de sync (`synced = false`)
- `cuadres` — pendiente de sync si se cerró turno offline

### Servicio de sincronización
- Se activa al detectar reconexión a internet (`connectivity_plus`)
- Lee todos los registros locales con `synced = false`
- Los sube a Supabase en orden cronológico
- Marca como `synced = true` al confirmar escritura en Supabase
- Descarga los cambios remotos y actualiza el caché local

---

## 8. Estructura de Carpetas del Proyecto Flutter

```
lib/
├── main.dart
├── app.dart                        # Inicialización de Supabase, Riverpod, go_router
│
├── core/
│   ├── router/
│   │   └── app_router.dart         # Rutas y redirección por rol
│   ├── theme/
│   │   └── app_theme.dart          # Colores, tipografía, estilos globales
│   ├── supabase/
│   │   └── supabase_client.dart    # Instancia global de Supabase
│   ├── local_db/
│   │   ├── local_database.dart     # Configuración de sqflite
│   │   └── sync_service.dart       # Lógica de sincronización offline→Supabase
│   └── utils/
│       └── connectivity_service.dart  # Detección de conexión
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── presentation/
│   │       └── login_screen.dart
│   │
│   ├── inventario/
│   │   ├── data/
│   │   │   ├── producto_repository.dart
│   │   │   └── categoria_repository.dart
│   │   ├── providers/
│   │   │   └── inventario_provider.dart
│   │   └── presentation/
│   │       ├── inventario_screen.dart
│   │       └── producto_form_screen.dart
│   │
│   ├── movimientos/
│   │   ├── data/
│   │   │   └── movimiento_repository.dart
│   │   ├── providers/
│   │   │   └── movimiento_provider.dart
│   │   └── presentation/
│   │       └── movimientos_screen.dart
│   │
│   ├── turno/
│   │   ├── data/
│   │   │   └── turno_repository.dart
│   │   ├── providers/
│   │   │   └── turno_provider.dart
│   │   └── presentation/
│   │       └── mi_turno_screen.dart
│   │
│   └── cuadres/
│       ├── data/
│       │   └── cuadre_repository.dart
│       ├── providers/
│       │   └── cuadre_provider.dart
│       └── presentation/
│           ├── cuadres_screen.dart
│           └── cuadre_detalle_screen.dart
│
└── shared/
    ├── widgets/
    │   ├── indicador_conexion.dart
    │   ├── stock_badge.dart
    │   └── loading_overlay.dart
    └── models/
        ├── usuario.dart
        ├── producto.dart
        ├── movimiento.dart
        └── cuadre.dart
```

---

## 9. Dependencias Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Backend
  supabase_flutter: ^2.x.x         # Auth + DB + Storage + Realtime

  # Estado
  flutter_riverpod: ^2.x.x         # Manejo de estado

  # Navegación
  go_router: ^13.x.x               # Rutas declarativas + redirect por rol

  # Offline
  sqflite: ^2.x.x                  # SQLite local
  path: ^1.x.x                     # Rutas de archivos locales

  # Conectividad
  connectivity_plus: ^6.x.x        # Detectar conexión a internet

  # UI
  cached_network_image: ^3.x.x     # Caché de imágenes de productos
  image_picker: ^1.x.x             # Seleccionar foto del producto

  # Utilidades
  uuid: ^4.x.x                     # Generación de IDs locales para offline
  intl: ^0.19.x                    # Formato de fechas
```

---

## 10. Variables de Entorno

Crear archivo `lib/core/supabase/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'TU_SUPABASE_URL';
  static const String anonKey = 'TU_SUPABASE_ANON_KEY';
}
```

> ⚠️ Agregar este archivo a `.gitignore` si el proyecto se sube a un repositorio.

---

## 11. Flujo Completo: Cerrar Turno (Dependiente)

```
1. Dependiente abre MiTurnoScreen
2. App consulta movimientos del día desde SQLite local
3. Dependiente presiona "Cerrar Turno"
4. App calcula totales (entradas, salidas)
5. App crea registro en cuadres (SQLite local, synced = false)
6. Si hay internet → sync inmediato a Supabase → synced = true
7. Si no hay internet → queda en SQLite → sync automático al reconectar
8. Admin ve el cuadre en CuadresScreen con estado "pendiente"
9. Admin abre CuadreDetalleScreen → presiona Aprobar o Rechazar
10. Estado se actualiza en Supabase → Realtime notifica al dependiente
```

---

## 12. Consideraciones Finales para el Agente de IA

- Cada `feature` es autónoma: tiene su propio `repository`, `provider` y `presentation`
- Los `repositories` son la única capa que habla con Supabase o SQLite — nunca acceder a Supabase directamente desde la UI
- Los `providers` de Riverpod exponen el estado a la UI y llaman a los repositories
- El `sync_service` corre en background y es independiente de las features
- Todo ID generado offline debe ser un `uuid v4` para evitar conflictos al sincronizar
- El campo `synced` en SQLite es la única fuente de verdad para saber qué falta subir
- Los modelos (`/shared/models/`) tienen métodos `toJson()`, `fromJson()`, `toLocalMap()` y `fromLocalMap()` para manejar tanto Supabase como SQLite

# Guía de Uso - Sistema de Movimientos

## Descripción General

La nueva pantalla de movimientos (`MovimientosAdminScreen`) funciona estilo WhatsApp, mostrando el historial desde abajo hacia arriba (lo más reciente primero) con divisiones por fecha.

## Tipos de Movimientos

### 1. Entrada de Producto (Azul)
Indica que se aumentó el stock de un producto.

```dart
// Registrar entrada de producto
ref.read(movimientoControllerProvider.notifier).registrarMovimiento(
  producto: producto,
  usuario: usuario,
  tipo: MovimientoTipo.entrada,
  cantidad: 10,
  nota: 'Compra de mercancía',
);
```

**Visualización:**
- Icono: Flecha azul hacia la derecha (→)
- Color: `context.colors.info` (azul)
- Muestra: nombre del producto y cantidad agregada

### 2. Disminución de Producto (Naranja)
Indica que se disminuyó manualmente el stock de un producto.

```dart
// Registrar disminución de producto
ref.read(movimientoControllerProvider.notifier).registrarMovimiento(
  producto: producto,
  usuario: usuario,
  tipo: MovimientoTipo.salida,
  cantidad: 5,
  nota: 'Ajuste de inventario',
);
```

**Visualización:**
- Icono: Flecha naranja hacia la izquierda (←)
- Color: `context.colors.warning` (naranja)
- Muestra: nombre del producto y cantidad disminuida

### 3. Inicio de Turno (Verde)
Indica que un dependiente inició su turno.

```dart
// Registrar inicio de turno
ref.read(movimientoControllerProvider.notifier).registrarInicioTurno(
  dependiente: dependiente,
);
```

**Visualización:**
- Icono: Login (puerta con flecha)
- Color: `context.colors.success` (verde)
- Muestra: nombre del dependiente

### 4. Venta (Azul Primario)
Indica una venta realizada por un dependiente. Tiene detalles expandibles.

```dart
// Registrar venta completa
ref.read(movimientoControllerProvider.notifier).registrarVenta(
  ventaId: venta.id,
  dependiente: dependiente,
  productos: [
    {'nombre': 'Llanta Michelin', 'cantidad': 2, 'precio': 50000.0},
    {'nombre': 'Aceite Mobil 1', 'cantidad': 1, 'precio': 35000.0},
  ],
  totalVenta: 135000.0,
);
```

**Visualización:**
- Icono: Carrito de compras
- Color: `context.colors.primary` (azul primario)
- Muestra: monto total, dependiente
- **Expandible**: Al tocar se muestra la lista de productos vendidos
- Botón para ver detalle completo de la venta

### 5. Producto Eliminado (Rojo)
Indica que el admin eliminó un producto del inventario.

```dart
// Registrar eliminación de producto
ref.read(movimientoControllerProvider.notifier).registrarProductoEliminado(
  producto: producto,
  admin: admin,
  motivo: 'Producto descontinuado',
);
```

**Visualización:**
- Icono: Basura
- Color: `context.colors.danger` (rojo)
- Muestra: nombre del producto y motivo (si existe)

## Integración con el Sistema Actual

### Al Crear una Venta

Cuando se completa una venta en `ConfirmarPagoScreen`, debes registrar el movimiento:

```dart
// Después de guardar la venta
final venta = /* tu objeto Venta */;

ref.read(movimientoControllerProvider.notifier).registrarVenta(
  ventaId: venta.id,
  dependiente: usuario,
  productos: venta.items.map((item) => {
    'nombre': item.productoNombre,
    'cantidad': item.cantidad,
    'precio': item.precioUnitario,
  }).toList(),
  totalVenta: venta.total,
);
```

### Al Iniciar Turno

En la pantalla `MiTurnoScreen`, cuando el dependiente inicia su turno:

```dart
ref.read(movimientoControllerProvider.notifier).registrarInicioTurno(
  dependiente: usuario,
);
```

### Al Eliminar un Producto

En la pantalla de detalle de producto o inventario:

```dart
// Antes de eliminar el producto de la BD
ref.read(movimientoControllerProvider.notifier).registrarProductoEliminado(
  producto: producto,
  admin: currentUser,
  motivo: 'Producto descontinuado', // Opcional
);

// Luego eliminar el producto...
```

## Características de la UI

### Scroll Invertido
La lista usa `reverse: true`, lo que significa:
- El contenido más reciente aparece en la parte inferior
- Al abrir la pantalla, ves automáticamente los movimientos de hoy
- Haces scroll hacia arriba para ver movimientos más antiguos

### Divisiones por Fecha
Las fechas se muestran como:
- **"Hoy"** - para movimientos del día actual
- **"Ayer"** - para movimientos de ayer
- **"DD/MM/YYYY"** - para fechas anteriores

### Orden dentro del Día
Dentro de cada día, los movimientos se muestran del más reciente al más antiguo (hacia arriba en la vista).

## Estructura de Base de Datos

El esquema actualizado de la tabla `movimientos` incluye:

```sql
CREATE TABLE movimientos (
  id TEXT PRIMARY KEY,
  producto_id TEXT NOT NULL,
  producto_nombre TEXT NOT NULL,
  usuario_id TEXT NOT NULL,
  usuario_nombre TEXT NOT NULL,
  usuario_foto_url TEXT,
  tipo TEXT NOT NULL, -- entrada, salida, inicioTurno, venta, productoEliminado
  cantidad INTEGER NOT NULL,
  nota TEXT,
  fecha TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  venta_id TEXT, -- Para ventas, referencia a la venta
  precio_unitario REAL, -- Para items individuales de venta
  total_venta REAL, -- Total de la venta
  productos_vendidos TEXT -- JSON array de productos en la venta
)
```

## Notas Importantes

1. **Compatibilidad hacia atrás**: Los movimientos antiguos (entrada/salida) siguen funcionando.

2. **Migración automática**: La base de datos se actualiza automáticamente a la versión 8.

3. **Productos vendidos**: Se almacenan como JSON string en SQLite para mantener la lista de productos en cada venta.

4. **TODO**: Implementar la navegación al detalle de venta cuando se toca "Ver detalle completo" en las cards de venta.

5. **Filtros**: Los filtros existentes en `MovimientosFilterSheet` deben actualizarse para incluir los nuevos tipos si es necesario.

# TODO: Correcciones pantalla "Movimientos" (Admin)

> Pantalla con 2 pestañas — "Productos" (agregado por producto) y "Por ventas"
> (agregado por transacción POS). Ambas leen del mismo estado de filtros.
> Feature afectado: `lib/features/movimientos/` (ver `ARQUITECTURA.md` del proyecto).

---

## Decisiones ya confirmadas con el dueño del proyecto

- Filtro de fecha con atajos **Hoy / Semana / Mes** + opción de **rango personalizado**
- Búsqueda encuentra por **nombre de producto Y nombre de dependiente**
- Filtro de tipo (**Todos / Entradas / Salidas**), fecha y búsqueda son **compartidos** entre "Productos" y "Por ventas" — un solo estado de filtros para toda la pantalla, no se resetea al cambiar de tab
- Mostrar **entradas y salidas por separado** por producto, no solo el neto

---

## Archivos que se van a tocar (no crear estructura nueva)

```
lib/features/movimientos/
  ├── data/movimiento_repository.dart          ← interfaz abstracta MovimientoRepository
  ├── data/movimiento_repository_memoria.dart  ← implementación en memoria (activa ahora)
  ├── data/movimiento_repository_supabase.dart ← implementación Supabase (para después, ver Anexo)
  ├── providers/movimiento_provider.dart       ← agregar MovimientosFilterState + notifier
  └── presentation/
        ├── movimientos_screen.dart         ← agregar SearchBar + selector de fecha
        ├── productos_tab.dart              ← agregar breakdown, agrupamiento, iconos
        └── por_ventas_tab.dart             ← sin cambios de fondo, solo lee el filtro compartido
```
Si los nombres de archivo reales difieren, usar la misma separación de responsabilidades (repository / provider / presentation), no meter lógica de Supabase directo en los widgets.

---

## Orden de implementación (seguir este orden, cada fase depende de la anterior)

1. Estado de filtros compartido (Fase 1)
2. Query a Supabase con filtros combinados (Fase 2)
3. Agregación y agrupamiento en "Productos" (Fase 3)
4. UI de búsqueda y selector de fecha (Fase 4)
5. Ajustes visuales y metadata (Fase 5)

No empezar la UI de filtros (Fase 4) sin tener el provider de Fase 1 funcionando — si se hace al revés, se termina duplicando estado local en cada tab.

---

## 🔴 Fase 1 — Estado de filtros compartido

- [ ] Crear una clase/record `MovimientosFilterState` con estos campos exactos:
  ```dart
  enum TipoMovimientoFiltro { todos, entradas, salidas }
  enum RangoFechaFiltro { hoy, semana, mes, personalizado }

  class MovimientosFilterState {
    final TipoMovimientoFiltro tipo;
    final RangoFechaFiltro rango;
    final DateTime? fechaInicioCustom;  // solo si rango == personalizado
    final DateTime? fechaFinCustom;     // solo si rango == personalizado
    final String query;                 // texto de búsqueda, '' si vacío
  }
  ```
- [ ] Crear un `NotifierProvider<MovimientosFilterNotifier, MovimientosFilterState>` (o `StateNotifierProvider` si el proyecto usa Riverpod 1.x) en `providers/movimiento_provider.dart`
- [ ] Ambas pestañas (`ProductosTab` y `PorVentasTab`) deben leer este mismo provider con `ref.watch(movimientosFilterProvider)` — **no crear estado local de filtros dentro de cada tab**
- [ ] El estado por defecto al entrar a la pantalla: `tipo: todos`, `rango: hoy`, `query: ''`
- [ ] Calcular `fechaInicio` / `fechaFin` reales a partir de `RangoFechaFiltro`:
  - `hoy` → medianoche local de hoy hasta medianoche local de mañana
  - `semana` → últimos 7 días incluyendo hoy (no "semana calendario lunes-domingo", salvo que el jefe prefiera eso — confirmar si hay duda, por defecto usar "últimos 7 días")
  - `mes` → últimos 30 días incluyendo hoy
  - `personalizado` → usar `fechaInicioCustom` y `fechaFinCustom` tal cual, inclusive en ambos extremos
  - Usar la zona horaria local del dispositivo, no UTC, para evitar que "Hoy" muestre movimientos de ayer/mañana por diferencia horaria

---

## 🔴 Fase 2 — Repositorio de datos (en memoria por ahora, Supabase después)

> El proyecto está usando datos en memoria en vez de Supabase por ahora (problemas de
> conectividad con el emulador de Android). Construir esta capa detrás de una interfaz
> para que reconectar Supabase más adelante sea solo cambiar una implementación, sin
> tocar el provider ni la UI para nada.

- [ ] Definir una interfaz `MovimientoRepository` (clase abstracta) con un único método:
  ```dart
  abstract class MovimientoRepository {
    Future<List<Movimiento>> getMovimientos(MovimientosFilterState filtro);
  }
  ```
- [ ] Implementar `InMemoryMovimientoRepository implements MovimientoRepository` que aplique el filtro sobre la lista/mock actual en memoria:
  - Tipo: incluir el movimiento solo si `filtro.tipo == todos` o `movimiento.tipo == filtro.tipo`
  - Fecha: incluir solo si `movimiento.fecha` cae entre `fechaInicio` (inclusive) y `fechaFin` (exclusive)
  - Búsqueda: si `filtro.query` no está vacío, incluir solo si el nombre del producto o el nombre del dependiente (en minúsculas) contienen el texto buscado
- [ ] El provider (`movimiento_provider.dart`) debe depender de la interfaz `MovimientoRepository`, nunca de `InMemoryMovimientoRepository` directamente — registrarla en un `Provider<MovimientoRepository>` para poder reemplazarla después sin tocar el resto del código
- [ ] No hace falta paginación ni optimización de performance en esta capa — el volumen de datos mock es mínimo, mantenerlo simple
- [ ] Ver el **Anexo** al final de este documento con el detalle exacto de la query de Supabase para cuando se reconecte — no implementarlo todavía

---

## 🔴 Fase 3 — Agregación y agrupamiento en "Productos"

- [ ] Agrupar los movimientos resultantes por `producto_id`
- [ ] Por cada producto, calcular:
  - `totalEntradas` = suma de `cantidad` donde `tipo == 'entrada'`
  - `totalSalidas` = suma de `cantidad` donde `tipo == 'salida'`
  - `neto` = `totalEntradas - totalSalidas`
- [ ] Mostrar SIEMPRE el desglose cuando ambos totales son mayores a 0: `↓ 5 entradas · ↑ 3 salidas`
- [ ] Si solo hay un tipo de movimiento (el caso más común), mostrar solo ese: `-3 unidades` (rojo) o `+5 unidades` (verde) — sin repetir el número dos veces como pasa hoy ("3 unidades -3")
- [ ] Corregir singular/plural en TODOS los contadores de la pantalla (unidad/unidades, movimiento/movimientos), no solo donde se detectó el bug. Usar un helper reutilizable:
  ```dart
  String pluralizar(int n, String singular, String plural) => n == 1 ? singular : plural;
  ```
- [ ] Definir explícitamente el color del ícono/badge según el neto:
  - `neto > 0` → verde (más entradas que salidas)
  - `neto < 0` → rojo (más salidas que entradas)
  - `neto == 0` → gris/neutral (caso borde: mismo número de entradas y salidas — no debe quedar sin definir ni causar error de rango de color)
- [ ] Agrupar la lista visualmente por fecha con headers ("Hoy", "Ayer", o la fecha formateada) igual que ya hace la pestaña "Por ventas" — esto aplica sobre todo cuando el rango activo es Semana/Mes/Personalizado, ya que con "Hoy" un solo grupo es suficiente

---

## 🟠 Fase 4 — UI de búsqueda y selector de fecha

- [ ] Agregar `SearchBar`/`TextField` en la parte superior de `movimientos_screen.dart`, reutilizando el mismo estilo visual que la barra de búsqueda de Inventario (mismo padding, bordes, ícono de lupa)
- [ ] **Debounce de 300-400ms** en el campo de búsqueda antes de disparar la query — no ejecutar una consulta a Supabase por cada tecla presionada
- [ ] Selector de fecha como fila de chips: `Hoy` / `Semana` / `Mes` / `Personalizado`, usando `ChoiceChip` o `SegmentedButton` (elegir el que ya se use en el resto de la app para mantener consistencia)
- [ ] Al tocar `Personalizado`, abrir `showDateRangePicker` (Flutter Material nativo) o un bottom sheet custom si no calza con el estilo iOS del resto de la app
- [ ] Mientras `fechaInicioCustom` o `fechaFinCustom` estén sin seleccionar (usuario tocó "Personalizado" pero no completó el rango), no disparar ninguna query nueva — mantener el filtro anterior activo hasta que el rango esté completo
- [ ] Mostrar un chip fijo y visible con el rango activo en todo momento, ej: `Mostrando: Esta semana (14–20 jul)` — debe actualizarse automáticamente al cambiar cualquier filtro
- [ ] Botón/ícono para limpiar todos los filtros de un tap (vuelve a: tipo=todos, rango=hoy, query='')
- [ ] Estado vacío: cuando la combinación de filtros no arroja resultados, mostrar un mensaje claro tipo "No hay movimientos en este rango" — no dejar la pantalla en blanco sin explicación
- [ ] Confirmar con el usuario si "Semana" debe ser "últimos 7 días" o "semana calendario (lunes a domingo)" antes de dar la Fase 1 por cerrada, en caso de que el repositorio ya tenga una convención distinta en otra parte de la app (ej. en Cuadres)

---

## 🟡 Fase 5 — Ajustes visuales y metadata

- [ ] Aplicar el separador `·` (punto medio) entre datos relacionados en las cards de "Productos", igual que ya usa "Por ventas" entre dependiente y fecha
- [ ] En cada card de producto en la pestaña "Productos", agregar quién hizo el último movimiento y cuándo — requiere traer `MAX(fecha)` agrupado por producto junto con el `usuario_id`/nombre asociado a ese registro más reciente
- [ ] Verificar que estos cambios no rompan el estado expandido (chevron) de cada card — si al expandir se listan los movimientos individuales, ese listado también debe respetar los filtros activos, no mostrar histórico completo sin filtrar

---

## Casos borde a no pasar por alto

- [ ] Producto con movimientos pero que fue eliminado/desactivado (`activo = false`) después — el movimiento histórico debe seguir mostrando el nombre del producto tal como estaba, no romper la UI ni mostrar "null"
- [ ] Cambiar de pestaña ("Productos" ↔ "Por ventas") no debe resetear ningún filtro activo, incluida la búsqueda de texto
- [ ] Cambiar cualquier filtro debe refrescar ambas pestañas, aunque el usuario esté viendo solo una — al volver a la otra pestaña ya debe reflejar el filtro nuevo, sin necesidad de recargar manualmente

---

## Checklist de aceptación (cómo probar que quedó bien)

- [ ] Filtrar por "Semana" y confirmar que el chip superior muestra el rango correcto de fechas
- [ ] Buscar el nombre de un dependiente y confirmar que aparecen sus movimientos aunque no coincida el nombre del producto
- [ ] Un producto con 5 entradas y 3 salidas en el rango muestra el desglose, no un neto de "+2"
- [ ] Un producto con cantidad = 1 en cualquier contador de la pantalla dice "unidad", no "unidades"
- [ ] Cambiar el filtro de tipo en "Productos" y verificar que "Por ventas" ya lo refleja al cambiar de tab
- [ ] Seleccionar "Personalizado" sin completar el rango no debe disparar ninguna query ni romper la pantalla
- [ ] Sin resultados para la combinación de filtros → se ve un mensaje, no una pantalla en blanco

---

## Anexo — Query de Supabase (para cuando se reconecte, NO implementar todavía)

- [ ] Crear `SupabaseMovimientoRepository implements MovimientoRepository` en `data/movimiento_repository_supabase.dart`, sin tocar el provider más que para cambiar qué implementación instancia
- [ ] Aplicar tipo: `.eq('tipo', 'entrada')` o `.eq('tipo', 'salida')` — si `tipo == todos`, no aplicar este filtro
- [ ] Aplicar fecha: `.gte('fecha', fechaInicio.toIso8601String()).lt('fecha', fechaFin.toIso8601String())` (usar `lt`, no `lte`, en el extremo superior para no duplicar el primer registro del día siguiente)
- [ ] Aplicar búsqueda:
  - La tabla `movimientos` no tiene el nombre del producto ni del usuario directamente, hay que traer las relaciones embebidas: `.select('*, productos(nombre), usuarios(nombre)')`
  - Para filtrar por texto en columnas de tablas embebidas, Supabase-Flutter soporta `.or('productos.nombre.ilike.%$query%,usuarios.nombre.ilike.%$query%')` — probar esta sintaxis primero
  - Si `.or()` sobre tablas embebidas no funciona en la versión del SDK instalada, hacer fallback: traer los resultados ya filtrados por tipo+fecha desde Supabase, y filtrar por `query` en el cliente — aceptable dado el volumen bajo por negocio
- [ ] No traer todos los movimientos sin filtro de fecha por defecto — el filtro por defecto sigue siendo "Hoy"

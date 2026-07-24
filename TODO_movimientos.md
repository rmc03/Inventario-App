# TODO: Pantalla "Movimientos" — feed único (sin pestañas)

> Cambio de dirección respecto a la versión anterior de este documento: se elimina
> el modelo de 2 pestañas (Productos / Actividad). Ahora es **una sola pantalla**
> con un feed cronológico de eventos. Se elimina también el concepto de merma/rojo.

---

## Resumen del cambio

- ❌ Se eliminan las pestañas "Productos" y "Actividad"/"Por ventas"
- ✅ Toda la funcionalidad que tenía "Actividad" (búsqueda, filtros de fecha, feed por día) pasa a ser el único contenido de la pantalla
- ❌ Se elimina toda la lógica de agregación por producto (neto, entradas/salidas por producto, color de ícono por neto) — ya no existe esa vista
- ❌ Se elimina el concepto de merma/pérdida y el color rojo — no aplica a este negocio, no implementar
- ✅ "Venta (POS)" se renombra a **"Venta"** en toda la UI
- ✅ Tocar una card de Venta abre el **recibo de la venta** — reutilizar el componente ya implementado en el flujo del Dependiente, no crear uno nuevo
- ✅ La búsqueda por producto debe encontrar coincidencias tanto en Entradas directas como dentro de los productos que componen una Venta

---

## Decisiones confirmadas

- Filtro de fecha: atajos **Hoy / Semana / Mes** + rango personalizado
- Búsqueda por **nombre de producto y nombre de dependiente**
- Colores finales (solo 3, sin rojo):
  - 🔵 Azul = Entrada (reposición de mercancía)
  - ⚪ Gris = Alta de producto (entrada por creación de producto nuevo)
  - 🟢 Verde = Venta

## Supuestos que estoy asumiendo (confirmar si algo no cuadra)

- [ ] El filtro de tipo pasa a ser **Todos / Entradas / Ventas** (se quita "Salidas" como nombre genérico — toda salida es ahora una venta, ya que no existe merma)
- [ ] "Alta de producto" cae dentro del filtro "Entradas" (técnicamente lo es), no es una categoría aparte en el filtro de tipo — solo se distingue por color/ícono dentro del feed
- [ ] Cuando la búsqueda encuentra el producto **dentro** de una venta (no en el título de la card), muestro debajo de esa card algo como "Coincide con: Aceite Motul 5100 10W-40" para que el jefe entienda por qué apareció esa venta — dime si prefieres que no se muestre nada extra y la venta aparezca "tal cual"

---

## Archivos afectados

```
lib/features/movimientos/
  ├── data/movimiento_repository.dart           ← interfaz abstracta MovimientoRepository
  ├── data/movimiento_repository_memoria.dart    ← implementación en memoria (activa ahora)
  ├── data/movimiento_repository_supabase.dart   ← implementación Supabase (después, ver Anexo)
  ├── providers/movimiento_provider.dart         ← MovimientosFilterState + notifier
  └── presentation/
        └── movimientos_screen.dart              ← pantalla única: búsqueda + filtros + feed
```
Ya NO existen `productos_tab.dart` ni `por_ventas_tab.dart` — se consolida en un solo widget de feed.
Para el recibo, ubicar el componente ya existente del lado del Dependiente (buscar en
`lib/features/turno/` o donde esté implementado el registro de venta) y reutilizarlo,
no crear una pantalla de recibo nueva desde cero.

---

## Orden de implementación

1. Quitar las pestañas y dejar un solo feed (Fase 1)
2. Ajustar el esquema de color a 3 categorías, sin rojo (Fase 2)
3. Repositorio de datos en memoria (Fase 3)
4. Búsqueda que entra a las líneas de una venta (Fase 4)
5. Recibo al tocar una Venta (Fase 5)
6. UI de filtros de fecha y búsqueda (Fase 6)

---

## 🔴 Fase 1 — Quitar las pestañas, dejar un solo feed

- [ ] Eliminar el segmented control "Productos" / "Por ventas" (o "Actividad") de `movimientos_screen.dart`
- [ ] El contenido que vivía en "Actividad" (búsqueda, filtros de fecha, feed cronológico agrupado por día con headers "Hoy"/"Ayer") pasa a ser el único contenido de la pantalla, sin nada arriba que seleccionar
- [ ] Eliminar toda la lógica de: suma de entradas/salidas por producto, cálculo de "neto", ícono cuyo color dependía del neto, agrupamiento por producto — nada de eso se usa ya
- [ ] La pantalla Inventario sigue siendo donde el jefe ve el stock actual por producto; Movimientos ya no duplica esa vista, solo muestra el historial cronológico de eventos

## 🔴 Fase 2 — Esquema de color final (sin rojo)

- [ ] Aplicar exactamente estos 3 colores, sin excepciones:
  - Azul = Entrada
  - Gris = Alta de producto
  - Verde = Venta
- [ ] **No implementar** ningún estado, campo, ícono o color para merma, pérdida, daño o ajuste negativo — está fuera de alcance por decisión del negocio
- [ ] Renombrar en TODA la UI: "Venta (POS)" → "Venta" (título de card, y cualquier otro texto donde aparezca "POS")

## 🔴 Fase 3 — Repositorio de datos (en memoria por ahora, Supabase después)

> El proyecto sigue usando datos en memoria en vez de Supabase (problemas de
> conectividad con el emulador de Android). Construir esta capa detrás de una
> interfaz para que reconectar Supabase después sea solo cambiar una implementación.

- [ ] Definir `MovimientoRepository` (clase abstracta) con un único método:
  ```dart
  abstract class MovimientoRepository {
    Future<List<Movimiento>> getMovimientos(MovimientosFilterState filtro);
  }
  ```
- [ ] Implementar `InMemoryMovimientoRepository implements MovimientoRepository` aplicando el filtro sobre la data mock actual:
  - Tipo: incluir solo si `filtro.tipo == todos` o coincide con `entrada`/`venta`
  - Fecha: incluir solo si la fecha cae entre `fechaInicio` (inclusive) y `fechaFin` (exclusive)
  - Búsqueda: ver Fase 4 (lógica especial para ventas)
- [ ] El provider debe depender de la interfaz `MovimientoRepository`, nunca de la implementación en memoria directamente — registrarla en un `Provider<MovimientoRepository>` para poder reemplazarla después
- [ ] No hace falta paginación ni optimización de performance en esta capa — el volumen de datos mock es mínimo

## 🟠 Fase 4 — Búsqueda que entra a las líneas de una Venta (importante, no lo simplifiques)

- [ ] Al buscar por nombre de producto, evaluar así según el tipo de card:
  - **Entrada / Alta de producto**: comparar contra el nombre del producto directo del movimiento
  - **Venta**: comparar contra el nombre de **cada producto dentro de la lista de items** de esa venta, no solo contra el título "Venta"
- [ ] Si algún producto dentro de una venta coincide con la búsqueda, esa card debe aparecer en los resultados aunque el título de la card sea "Venta" y no el nombre buscado
- [ ] Reutilizar la estructura de datos que ya existe para representar una venta con sus items (la que ya usa el Dependiente al registrarla) — no inventar un modelo nuevo de venta
- [ ] La búsqueda por nombre de dependiente sigue aplicando igual que antes, sobre cualquier tipo de card
- [ ] Ver el supuesto de "Coincide con: ..." arriba — implementarlo salvo que el jefe confirme que no lo quiere

## 🟠 Fase 5 — Recibo de venta al tocar la card

- [ ] Al tocar una card de tipo "Venta", navegar al componente/pantalla de recibo **ya implementado** en el flujo del Dependiente — buscarlo en el proyecto antes de crear nada nuevo
- [ ] El recibo se muestra en modo solo lectura para el Admin (mismo diseño que ve el Dependiente al vender, sin acciones de edición)
- [ ] Las cards de Entrada y Alta de producto no necesitan una vista de detalle nueva — mantener el comportamiento que ya tengan hoy, sin cambios

## 🟡 Fase 6 — UI de búsqueda y filtro de fecha

- [ ] Barra de búsqueda en la parte superior de `movimientos_screen.dart`, mismo estilo que la de Inventario
- [ ] Debounce de 300–400ms antes de disparar la búsqueda — no ejecutar en cada tecla
- [ ] Chips de fecha: `Hoy` / `Semana` / `Mes` / `Personalizado`; personalizado abre un date range picker
- [ ] Mientras el rango personalizado no esté completo, no disparar ninguna query nueva — mantener el filtro anterior activo
- [ ] Chip fijo visible con el rango activo (ej. "Mostrando: Esta semana"), se actualiza con cualquier cambio de filtro
- [ ] Botón para limpiar todos los filtros de un tap (tipo=todos, rango=hoy, query='')
- [ ] Estado vacío con mensaje claro cuando ningún resultado cumple los filtros activos

---

## Casos borde

- [ ] Un producto que coincide en varias ventas del mismo día debe mostrar todas esas cards, no colapsarlas en una
- [ ] Una venta sin productos que coincidan pero cuyo dependiente sí coincide con la búsqueda también debe aparecer
- [ ] Producto eliminado/desactivado después de la venta: la card y el recibo deben seguir mostrando el nombre tal como estaba en el momento de la venta, no romperse ni mostrar "null"
- [ ] Seleccionar "Personalizado" sin completar el rango no debe disparar ninguna query ni romper la pantalla

---

## Checklist de aceptación

- [ ] Ya no existen las pestañas "Productos" / "Actividad" — hay un solo feed
- [ ] Buscar "Aceite Motul" muestra tanto su entrada de reposición como cualquier venta que lo incluya, aunque la venta tenga otros productos también
- [ ] El texto "Venta (POS)" no aparece en ningún lado — ahora dice "Venta"
- [ ] Tocar una card de Venta abre el recibo ya existente, no un expand inline
- [ ] No existe ningún color rojo ni texto relacionado a merma/pérdida en la pantalla
- [ ] Filtrar por "Semana" y ver el chip superior con el rango correcto

---

## Anexo — Query de Supabase (para cuando se reconecte, NO implementar todavía)

- [ ] Crear `SupabaseMovimientoRepository implements MovimientoRepository` en `data/movimiento_repository_supabase.dart`, sin tocar el provider más que para cambiar qué implementación instancia
- [ ] Aplicar tipo: `.eq('tipo', 'entrada')` o `.eq('tipo', 'salida')` — si `tipo == todos`, no aplicar este filtro
- [ ] Aplicar fecha: `.gte('fecha', fechaInicio.toIso8601String()).lt('fecha', fechaFin.toIso8601String())`
- [ ] Para la búsqueda dentro de ventas, probablemente haga falta un join/embed a la tabla de items de venta (`.select('*, venta_items(productos(nombre))')` o el nombre real que tenga esa tabla) — revisar el modelo ya existente del lado del Dependiente antes de escribir esta query
- [ ] Si el filtro `.or()` sobre tablas embebidas no funciona en la versión del SDK instalada, hacer fallback filtrando en el cliente sobre los resultados ya acotados por tipo+fecha

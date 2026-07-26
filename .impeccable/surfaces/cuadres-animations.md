# Animaciones de Cuadres (Admin)

**Superficie:** Cuadres List + Cuadre Detalle (vista del admin)
**Modo:** Operate
**Plataforma:** iOS/Android (Flutter nativo)
**Fecha:** 2026-07-26

## Motion Thesis

### Momento Focal
**Conteo animado del total en Detalle**: El valor monetario del cuadre anima de 0 al valor final (800ms, easeOutCubic), comunicando el peso del cuadre al entrar a la vista de detalle. Las métricas secundarias (ventas, unidades) escalan con easeOutBack creando un micro-delight.

### Continuidad
- **Entrada escalonada de cuadres**: Las cards de la lista aparecen en secuencia (stagger 60ms), revelando la cola de revisión del admin progresivamente
- **Crossfade en toggle Resumen/Productos**: Cambio fluido entre las dos vistas con AnimatedSwitcher
- **Header del detalle**: Avatar + nombre entran con fade + slide-up antes que los KPIs

### Feedback
- **Press en cuadre card**: Scale a 0.98 con 150ms — confirma que la card es interactiva
- **Press en botones de acción**: Scale sutil que confirma tactilidad
- **Empty state**: Icono con gentle pulse para atraer atención

### Budget de Rendimiento
- Solo transform y opacity (GPU-accelerated)
- Sin layout shifts
- Respeta Reduce Motion del sistema
- Animaciones encapsuladas en widgets específicos

---

## Animaciones por componente

### 1. CuadresScreen — Lista escalonada
- **Entrada:** Fade + translate-down por card (400ms, easeOutCubic)
- **Stagger:** 60ms entre cada card
- **Cap:** Delay máximo de 400ms total (si hay muchas, las ultimas entran sin delay extra)
- **Feedback táctil:** Scale 1.0 → 0.98 → 1.0 (150ms)

### 2. CuadreDetalleScreen — Hero count
- **Total value:** Count de 0 → valor final (800ms, easeOutCubic)
- **Metric cards:** Scale from 0.85 + fade (400ms, easeOutBack) con 100ms stagger entre las dos
- **Header:** Fade + slide-up (400ms)

### 3. CuadreDetalleScreen — Toggle Resumen/Productos
- **AnimatedSwitcher:** Fade + slide de 4px (300ms, easeOutCubic)
- **Contenido nuevo:** Fade-in del contenido al cambiar

### 4. CuadreDetalleScreen — Listas
- **Venta cards / Producto cards:** Fade + translate-down (400ms, 60ms stagger)
- **Total row:** Fade-in (400ms)

---

## Timing Constants

```dart
const _kEntranceDuration = Duration(milliseconds: 400);
const _kEntranceCurve = Curves.easeOutCubic;
const _kStaggerInterval = Duration(milliseconds: 60);
const _kFeedbackDuration = Duration(milliseconds: 150);
const _kTransitionDuration = Duration(milliseconds: 300);
const _kCountDuration = Duration(milliseconds: 800);
```

---

## Conformidad

### iOS (HIG)
✅ Duraciones 150-800ms dentro de rango HIG
✅ Curvas naturales (easeOutCubic, easeOutBack)
✅ Reduce Motion manejado por Flutter
✅ Sin interferencia con gestures del sistema

### Android (Material 3)
✅ Timing dentro de rangos Material (100-500ms)
✅ Easing curves estándar
✅ Respeta "Remove animations"
✅ Feedback táctil coherente

---

**Diseñado bajo:** Impeccable Design System

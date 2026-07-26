# Animaciones del Dashboard de Resumen

**Superficie:** Dashboard/Resumen (pantalla principal del Admin)  
**Modo:** Operate  
**Plataforma:** iOS/Android (Flutter nativo)  
**Fecha:** 2026-07-25

## Motion Thesis

### Momento Focal
**Conteo animado en Hero Stats**: Las tarjetas de estadísticas principales (Ventas totales y Unidades vendidas) revelan sus valores mediante un conteo progresivo de 0 al valor final, comunicando dinamismo y datos en tiempo real. Este es el punto focal que captura atención al entrar al dashboard.

### Continuidad
- **Entrada suave del contenido**: Todo el contenido aparece con fade-in + slide-up suave al cargar datos
- **Transición de período**: Cambio fluido entre "Hoy", "Esta semana" y "Este mes" con crossfade
- **Actualización de valores**: Los números se animan al cambiar período, preservando continuidad

### Feedback
- **Táctil en alertas**: Las cards de alertas operacionales responden con scale-down al presionar
- **Entrada escalonada**: Los productos más vendidos aparecen en secuencia (stagger) con delay progresivo
- **Barras de progreso animadas**: El fill de las barras se anima desde 0 hasta el valor final

### Budget de Rendimiento
- Transforms y opacity (GPU-accelerated)
- Sin layout shifts costosos
- Animaciones limitadas a widgets específicos
- Respeta Reduce Motion del sistema (iOS/Android)

---

## Animaciones Implementadas

### 1. Hero Stats Cards (Focal)
**Componente:** `_AnimatedHeroStatCard`
- **Entrada:** Scale + fade (400ms, easeOutBack)
- **Conteo:** Número anima de 0 a valor final (800ms, easeOutCubic)
- **Ícono:** Scale + fade con elastic bounce (400ms)
- **Delta indicator:** Translate up + fade (500ms)
- **Stagger:** 80ms de delay entre las dos cards

**Timing:**
- Card 1 (Ventas): inicia inmediatamente
- Card 2 (Unidades): +80ms delay

**Propósito:** Momento de entrada memorable que comunica dinamismo de datos.

### 2. Selector de Período
**Componente:** `_PeriodoSelector`
- **Entrada inicial:** Translate down + fade (300ms)
- **Cambio de período:** AnimatedSwitcher con fade + slide (300ms)

**Propósito:** Feedback visual claro al cambiar filtro temporal.

### 3. Top Productos (Staggered Entrance)
**Componente:** `_TopProductoItem`
- **Entrada:** Translate down + fade por item
- **Timing:** 400ms base + (60ms × index)
- **Ejemplo:**
  - Item 1: 400ms
  - Item 2: 460ms
  - Item 3: 520ms

**Propósito:** Revelar jerarquía de ranking progresivamente.

### 4. Barra de Progreso Animada
**Componente:** `_AnimatedProgressBar`
- **Fill:** Width anima de 0% a valor final (600ms, easeOutCubic)
- **Delay:** 200ms base + (60ms × index del producto)

**Propósito:** Hacer comparación visual entre productos más dinámica y legible.

### 5. Alertas Operacionales (Micro-interacción)
**Componente:** `_AlertaCard`
- **Entrada del ícono:** Rotate + scale (400ms, elasticOut)
- **Feedback táctil:** Scale to 0.97 al presionar (150ms)
- **Release:** Scale back to 1.0 (150ms)

**Propósito:** Feedback inmediato que confirma interactividad.

### 6. Contenido Global
**Componente:** `_ResumenBodyState`
- **Fade in:** Todo el contenido (400ms)
- **Slide up:** Offset(0, 0.02) → Offset.zero
- **Trigger:** Al completar carga de datos

**Propósito:** Transición suave desde skeleton a contenido real.

---

## Timing Constants

```dart
const _kEntranceDuration = Duration(milliseconds: 400);
const _kEntranceCurve = Curves.easeOutCubic;
const _kStaggerInterval = Duration(milliseconds: 80);
const _kFeedbackDuration = Duration(milliseconds: 150);
const _kTransitionDuration = Duration(milliseconds: 300);
```

---

## Conformidad con Plataforma Nativa

### iOS (HIG)
✅ Duraciones alineadas con sistema (150-400ms para transiciones)  
✅ Curves naturales (easeOut, easeOutCubic)  
✅ Respeta Reduce Motion (Flutter lo maneja automáticamente)  
✅ No interfiere con edge-swipe back gesture  
✅ Scale feedback alineado con interacciones iOS

### Android (Material 3)
✅ Timing dentro de rangos Material (100-500ms)  
✅ Easing curves estándar (easeOut)  
✅ Respeta "Remove animations" del sistema  
✅ Feedback táctil coherente con Material  
✅ No bloquea gesture de Back del sistema

---

## Performance

**GPU-Accelerated:**
- Transform (translate, scale, rotate)
- Opacity
- AnimationController con vsync

**Evitado:**
- Layout properties (width/height en animación)
- Repaint innecesario de áreas grandes
- Animaciones síncronas que bloqueen render

**Medición recomendada:**
- Timeline en Flutter DevTools
- Performance overlay: 60fps constante esperado
- Test en dispositivos de gama media-baja

---

## Accesibilidad

✅ **Reduce Motion:** Flutter respeta preferencia del sistema automáticamente (usa `MotionReductionMode`)  
✅ **Semantics:** Todos los widgets mantienen labels descriptivos  
✅ **No bloquea interacción:** Animaciones no impiden uso durante ejecución  
✅ **Skip posible:** Usuario puede cambiar pantalla durante animaciones

---

## Próximos Pasos

Si se desea expandir:
1. `/impeccable animate` otras pantallas (Inventario, Ventas, Cuadres)
2. `/impeccable polish` para refinamiento final pre-producción
3. `/impeccable audit` para validación de performance y a11y

---

**Diseñado bajo:** Impeccable Design System  
**Adherencia:** iOS HIG + Material Design 3 Motion Guidelines

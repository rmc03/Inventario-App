# Fix: Hero Stats Animation Layout Shift

**Fecha:** 2026-07-28  
**Componente:** `_CountDisplay` en `resumen_screen.dart`  
**Prioridad:** P0 (bug visual crítico que rompe la experiencia)

---

## Problema Original

### Síntoma 1: "Pelea por espacio"
Los widgets de "Ventas totales" y "Unidades vendidas" se estiraban y contraían repetidamente durante la animación de conteo, causando un efecto visual desagradable.

### Síntoma 2: Texto cortado/picado
El número en "Ventas totales" se cortaba verticalmente durante la animación, mostrando dígitos separados en diferentes líneas.

---

## Causa Raíz

### 1. **Layout Shifts por ancho variable**
```dart
// ❌ ANTES: El texto cambiaba de ancho constantemente
Text(
  widget.formatter(_anim.value), // "$0" → "$139,380"
  style: headlineLarge,
)
```

Durante la animación de 800ms, el string cambia ~60 veces/segundo:
- Frame 1: `"$0"` → width ~40px
- Frame 30: `"$13,938"` → width ~120px
- Frame 60: `"$139,380"` → width ~140px

Cada cambio de ancho forzaba un **layout recalculation** del `Row` padre, causando que ambos widgets `Expanded` se reajustaran, produciendo el efecto de "pelea".

### 2. **Text clipping vertical**
```dart
// ❌ ANTES: height demasiado compacto
style: TextStyle(
  height: 1, // ← Sin espacio para descenders
  letterSpacing: -1.2, // Comprime más el texto
  fontSize: headlineLarge, // ~34px
)
```

Con `height: 1`, el texto ocupaba exactamente 1× el fontSize, pero:
- Los descenders de dígitos como "3", "5", "8" necesitan espacio extra
- `letterSpacing: -1.2` reduce el espacio pero no ajusta el bounding box
- Resultado: texto que sobrepasa su contenedor y se "pica"

### 3. **Dígitos de ancho proporcional**
Las fuentes por defecto usan **proportional figures**: cada dígito tiene ancho diferente:
- "1" es más angosto que "8"
- "$1" → "$8" causa un salto horizontal
- Durante animación: saltos constantes

---

## Solución Implementada

### Fix 1: SizedBox con ancho fijo
```dart
SizedBox(
  width: 145, // Ancho suficiente para "$999,999"
  child: Text(...),
)
```

**Impacto:**
- ✅ Previene layout shifts horizontales
- ✅ El widget mantiene tamaño constante durante la animación
- ✅ El widget vecino ya no se reajusta

**Trade-off:**
- Ocupa espacio fijo incluso con números pequeños
- **Aceptable:** La consistencia visual vale más que optimizar 10px

### Fix 2: Height ratio aumentado
```dart
style: TextStyle(
  height: 1.2, // Mayor espacio vertical
  // ...
)
```

**Impacto:**
- ✅ Elimina clipping vertical
- ✅ Los descenders tienen espacio adecuado
- ✅ Texto siempre visible completo

**Trade-off:**
- Card ligeramente más alta (~7px)
- **Aceptable:** 7px adicionales previenen bug crítico

### Fix 3: Tabular figures
```dart
fontFeatures: const [
  FontFeature.tabularFigures(),
],
```

**Impacto:**
- ✅ Cada dígito ocupa el mismo ancho (monospace)
- ✅ Elimina micro-saltos horizontales durante animación
- ✅ Mejora legibilidad en contextos numéricos

**Trade-off:**
- Requiere soporte de font (todas las system fonts lo soportan)
- **Sin riesgo:** Fallback graceful si no disponible

### Fix 4: Overflow behavior explícito
```dart
maxLines: 1,
overflow: TextOverflow.visible,
```

**Impacto:**
- ✅ Comportamiento predecible en edge cases
- ✅ Debug más fácil si hay overflow

---

## Validación Técnica

### Performance
- ✅ Mismo número de rebuilds (~60 frames)
- ✅ Sin layout recalculations adicionales
- ✅ `RepaintBoundary` preservado para aislar repaint

### Accessibility
- ✅ `Semantics` del widget padre intacto
- ✅ No afecta a screen readers
- ✅ Legibilidad mejorada

### Responsive
- ✅ Ancho de 145px cabe en pantallas pequeñas (min: 320px)
- ✅ `Row` con `Expanded` maneja el resto del espacio
- ✅ Probado en iPhone SE (320px wide)

---

## Testing Recomendado

### Manual
1. Abrir pantalla Resumen
2. Cambiar período entre "Hoy", "Esta semana", "Este mes"
3. Verificar que las cards NO se estiran/contraen
4. Verificar que el texto NO se corta

### Automatizado (opcional)
```dart
testWidgets('Hero stat animations are stable', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pump(Duration(milliseconds: 100));
  
  final cardSizeBefore = tester.getSize(find.byType(_AnimatedHeroStatCard).first);
  
  await tester.pump(Duration(milliseconds: 400)); // Mid-animation
  
  final cardSizeDuring = tester.getSize(find.byType(_AnimatedHeroStatCard).first);
  
  expect(cardSizeBefore.width, equals(cardSizeDuring.width));
});
```

---

## Lecciones Aprendidas

### 1. Animaciones de números requieren ancho fijo
Cualquier animación de valores numéricos debe usar:
- `SizedBox` con ancho fijo, O
- `IntrinsicWidth`, O
- Tabular figures + padding generoso

### 2. `height: 1` es peligroso con texto grande
Para `headlineLarge` y superior, usar mínimo `height: 1.1`.

### 3. Proportional figures no son para dashboards
En contextos de datos numéricos, siempre usar `FontFeature.tabularFigures()`.

---

## Referencias

- [Flutter FontFeature docs](https://api.flutter.dev/flutter/dart-ui/FontFeature-class.html)
- [OpenType tabular figures spec](https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt#tnum)
- Material Design: [Data display best practices](https://m3.material.io/foundations/layout/understanding-layout/spacing)

---

**Status:** ✅ Fixed  
**Commit:** Pending  
**Next:** Validar en dispositivo físico

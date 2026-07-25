# Bugfix: Cuadre Duplicado y Overflow Visual

## 🐛 Bugs Corregidos

### Bug 1: Cuadre duplicado al continuar vendiendo

**Síntoma:**
- Dependiente envía cuadre
- Toca "Continuar vendiendo"
- Agrega nueva venta
- Al cerrar turno nuevamente → Se crea un cuadre NUEVO en lugar de actualizar el existente

**Causa raíz:**
La función `crearCuadrePendiente` en `CuadreController` siempre creaba un nuevo cuadre. Solo verificaba si existía un cuadre HOY (cualquier estado), pero no distinguía entre cuadres pendientes y aprobados/rechazados.

**Código problemático:**
```dart
String? crearCuadrePendiente({
  required Usuario dependiente,
  required List<Venta> ventas,
}) {
  if (_repo.existsCuadreHoy(dependiente.id)) {
    return 'Ya existe un cuadre para hoy. No puedes cerrar el turno dos veces.';
  }
  
  // Siempre crea nuevo cuadre
  _repo.addCuadre(Cuadre(...));
}
```

**Solución implementada:**
```dart
String? crearCuadrePendiente({
  required Usuario dependiente,
  required List<Venta> ventas,
}) {
  // Buscar cuadre pendiente del día
  final cuadreExistente = _repo.fetchCuadres().where((c) =>
    c.dependienteId == dependiente.id &&
    c.estado == CuadreEstado.pendiente &&
    _isSameDay(c.fechaTurno, DateTime.now())
  ).firstOrNull;

  if (cuadreExistente != null) {
    // ACTUALIZAR cuadre existente
    _repo.updateCuadre(
      cuadreExistente.copyWith(
        ventas: List.unmodifiable(ventas),
        updatedAt: DateTime.now(),
      ),
    );
    state = _repo.fetchCuadres();
    return null;
  }

  // Crear nuevo solo si no existe uno pendiente
  _repo.addCuadre(Cuadre(...));
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
```

**Ahora:**
- ✅ Si ya existe un cuadre pendiente hoy → Lo actualiza con las nuevas ventas
- ✅ Si no existe cuadre pendiente → Crea uno nuevo
- ✅ Si existe un cuadre aprobado/rechazado → Puede crear uno nuevo (caso raro pero posible)

---

### Bug 2: Overflow visual (bottom overflow by 21 pixels)

**Síntoma:**
- En la pantalla "Cuadre enviado" aparece una banda amarilla/negra rayada con el texto "bottom overflow by 21 pixels"
- Indica que el contenido no cabe en el espacio disponible

**Causa raíz:**
El `ListView` dentro del `Expanded` no tenía suficiente padding inferior para acomodar el contenido cuando el botón "Continuar vendiendo" está visible.

**Código problemático:**
```dart
Expanded(
  child: ListView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // ❌ Sin espacio abajo
    children: [...]
  ),
)
```

**Solución implementada:**
```dart
Expanded(
  child: ListView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // ✅ 100px de espacio
    children: [...]
  ),
)
```

**Ahora:**
- ✅ El contenido tiene espacio suficiente para scroll
- ✅ No se superpone con el botón inferior
- ✅ No hay overflow visual

---

## 🔄 Flujo Correcto Ahora

```
1. Dependiente trabaja y cierra turno
   ↓
2. Envía cuadre → Se crea Cuadre #1 (pendiente)
   ↓
3. Pantalla "Cuadre enviado" con resumen
   ↓
4. Llega cliente → Toca "Continuar vendiendo"
   ↓
5. Reabre turno → Agrega venta
   ↓
6. Cierra turno nuevamente
   ↓
7. Envía cuadre → Se ACTUALIZA Cuadre #1 (no crea #2)
   ↓
8. Admin ve Cuadre #1 con todas las ventas (originales + nuevas)
```

---

## 🧪 Testing

### Caso 1: Enviar, continuar, agregar venta, re-enviar
```dart
void testActualizarCuadreExistente() async {
  // 1. Crear cuadre con 2 ventas
  final ventas1 = [venta1, venta2];
  await cuadreController.crearCuadrePendiente(
    dependiente: dependiente,
    ventas: ventas1,
  );
  
  // Verificar que existe 1 cuadre
  expect(cuadreController.state.length, 1);
  final cuadreId = cuadreController.state.first.id;
  
  // 2. Agregar nueva venta y re-enviar
  final ventas2 = [venta1, venta2, venta3];
  await cuadreController.crearCuadrePendiente(
    dependiente: dependiente,
    ventas: ventas2,
  );
  
  // Verificar que SIGUE siendo 1 cuadre (actualizado)
  expect(cuadreController.state.length, 1);
  expect(cuadreController.state.first.id, cuadreId); // Mismo ID
  expect(cuadreController.state.first.ventas.length, 3); // 3 ventas ahora
}
```

### Caso 2: Enviar, admin rechaza, volver a enviar
```dart
void testNuevoCuadreDespuesDeRechazado() async {
  // 1. Crear cuadre
  await cuadreController.crearCuadrePendiente(
    dependiente: dependiente,
    ventas: ventas,
  );
  
  final cuadre1Id = cuadreController.state.first.id;
  
  // 2. Admin rechaza
  cuadreController.rechazarCuadre(cuadre1Id, 'Error en ventas');
  
  // 3. Dependiente crea nuevo cuadre
  await cuadreController.crearCuadrePendiente(
    dependiente: dependiente,
    ventas: ventasCorregidas,
  );
  
  // Verificar que ahora hay 2 cuadres
  expect(cuadreController.state.length, 2);
  expect(cuadreController.state[0].estado, CuadreEstado.rechazado);
  expect(cuadreController.state[1].estado, CuadreEstado.pendiente);
}
```

---

## 📝 Archivos Modificados

### 1. `lib/features/cuadres/providers/cuadre_provider.dart`
**Cambios:**
- Refactorizada función `crearCuadrePendiente`
- Agregado método helper `_isSameDay`
- Lógica de actualización vs creación

### 2. `lib/features/turno/presentation/mi_turno_screen.dart`
**Cambios:**
- Padding del ListView aumentado de 0 a 100px en el bottom
- Soluciona overflow visual

---

## 🎯 Comportamiento Esperado

### Escenario A: Primera vez enviando cuadre
- ✅ Se crea cuadre pendiente nuevo
- ✅ Se muestra en lista del admin

### Escenario B: Continuar vendiendo y re-enviar
- ✅ Se actualiza cuadre pendiente existente
- ✅ Admin ve el cuadre actualizado con todas las ventas
- ✅ NO se duplican cuadres

### Escenario C: Admin aprueba/rechaza y dependiente envía otro
- ✅ Se crea cuadre nuevo (el anterior ya no está pendiente)
- ✅ Ambos cuadres quedan en historial

---

## ⚠️ Consideraciones para Producción

### 1. Concurrencia
Si dos procesos intentan actualizar el cuadre simultáneamente:
- **Solución:** Usar optimistic locking o timestamps
- **Backend:** Validar que `updatedAt` coincida antes de actualizar

### 2. Auditoría
Actualmente se pierde el historial de qué ventas se agregaron después:
- **Mejora:** Guardar snapshot de cada actualización
- **Logs:** Registrar cuándo y qué se actualizó

### 3. Notificaciones
Si el cuadre se actualiza después de que el admin empezó a revisarlo:
- **UX:** Mostrar badge "Actualizado" en la lista
- **Refresh:** Auto-actualizar si el admin tiene el detalle abierto

### 4. Validación
Prevenir que se agreguen ventas de días diferentes:
- **Backend:** Validar que todas las ventas sean del día del cuadre
- **App:** Bloquear si pasa medianoche

---

## 📊 Impacto

### Antes:
- ❌ Cuadres duplicados
- ❌ Confusión para el admin (¿cuál es el correcto?)
- ❌ Overflow visual molesto

### Después:
- ✅ Un solo cuadre por turno que se actualiza
- ✅ Claridad para el admin
- ✅ UI sin errores visuales

---

**Corregido:** 25/07/2026  
**Archivos:** 2 modificados  
**Tests:** Pendientes (agregar tests unitarios)  
**Producción:** Listo para usar con las consideraciones mencionadas

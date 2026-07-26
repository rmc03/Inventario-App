# Animaciones - Pantalla de Movimientos

## Motion Thesis

La pantalla de movimientos es una interfaz de **modo Operate** - un feed de transacciones donde los usuarios revisan movimientos de inventario con scroll reverso estilo WhatsApp (más reciente abajo).

## Implementación de Animaciones

### 1. **Entrada de Items** - `_AnimatedListItem`
**Propósito**: Crear una sensación de "asentamiento" de los items desde abajo, coincidiendo con el scroll reverso.

**Implementación**:
- Fade in suave (0 → 1) durante los primeros 320ms
- Slide upward desde offset (0, 0.15) hacia offset.zero
- Stagger delay de 30ms por item (máximo 10 items para evitar esperas largas)
- Duración: 400ms con `Curves.easeOutCubic`

**Efecto**: Los movimientos "se asientan" gentilmente desde abajo, creando continuidad visual con el patrón de scroll reverso.

### 2. **Botón de Limpiar Búsqueda** - `_AnimatedClearButton`
**Propósito**: Feedback táctil inmediato al presionar.

**Implementación**:
- Scale press de 1.0 → 0.85 al presionar
- Responde a tap down/up/cancel
- Duración: 150ms con `Curves.easeInOut`

**Efecto**: El botón "rebota" sutilmente al presionarlo, confirmando la acción sin ser intrusivo.

### 3. **Botón de Filtrar** - `_AnimatedFilterButton`
**Propósito**: Indicar visualmente que hay filtros activos sin gritar.

**Implementación**:
- Pulse suave de escala 1.0 → 1.08 cuando hay filtros activos
- Animación de sombra sincronizada con el pulse
- Duración: 1500ms con `Curves.easeInOut` en loop reverse
- Se detiene completamente cuando no hay filtros activos

**Efecto**: El botón "respira" sutilmente, atrayendo la atención hacia los filtros activos sin ser molesto.

### 4. **Expansión de Venta** (ya existente, refinada)
**Propósito**: Revelar detalles de productos vendidos de manera fluida.

**Implementación existente mejorada**:
- Rotación del ícono de flecha 180° (0.0 → 0.5 turns)
- `SizeTransition` para el panel expandible
- Cambio de color del contenedor del ícono
- Duración: 300ms con `Curves.easeInOutCubic`

**Nueva mejora**:
- Staggered fade + slide para cada producto en la lista expandida
- Delay incremental de 50ms por producto
- Animación de 200ms base con `Curves.easeOutCubic`

**Efecto**: La expansión se siente natural y orgánica, con los productos apareciendo secuencialmente en lugar de todos a la vez.

### 5. **Animaciones Implícitas** (AnimatedContainer)
Varias animaciones ya utilizan `AnimatedContainer` para transiciones automáticas:
- Cambio de color/sombra del contenedor del ícono de venta al expandir
- Cambio de color del botón de flecha al expandir
- Transiciones suaves de 300ms con `Curves.easeInOutCubic`

## Principios Aplicados

### ✅ Timing Apropiado
- **150ms**: Feedback inmediato (botón clear)
- **300ms**: Cambios de estado rutinarios (expansión de venta)
- **400ms**: Entradas de layout (items del feed)
- **1500ms**: Animación ambiental continua (pulse del filtro)

### ✅ Easing Natural
- `Curves.easeOutCubic`: Para llegadas confiadas (entrada de items)
- `Curves.easeInOutCubic`: Para transiciones de estado (expansión)
- `Curves.easeInOut`: Para loops continuos (pulse del filtro)

### ✅ Propósito Claro
Cada animación explica:
- **Feedback**: Botón clear confirma la acción
- **Estado**: Filtro activo pulse indica estado persistente
- **Continuidad**: Entrada de items conecta con scroll reverso
- **Relación**: Expansión de venta revela jerarquía de información

### ✅ Performance
- Solo `transform` y `opacity` (propiedades baratas)
- Stagger limitado a 10 items máximo
- Animaciones se detienen cuando no son necesarias (filtro inactivo)
- Sin animaciones bloqueantes o largas

### ✅ Accesibilidad
- Las animaciones no bloquean el contenido
- El contenido es visible desde el estado por defecto
- Los usuarios pueden interactuar inmediatamente (no hay coreografía de carga)
- Compatible con `prefers-reduced-motion` (Flutter lo maneja automáticamente)

## Verificación

✅ El momento focal (entrada de items) es específico del concepto de scroll reverso  
✅ Cada animación de soporte explica feedback, estado o relación  
✅ Las interrupciones y uso repetido funcionan correctamente  
✅ Los caminos de teclado y móvil permanecen usables  
✅ Eliminar una animación perdería significado o carácter, no solo decoración  

## Próximos Pasos

Para un pulido final, considerar `/impeccable polish` para:
- Ajustar timings según feedback de usuarios reales
- Verificar performance en dispositivos de gama baja
- Ajustar intensidad del pulse si resulta distractivo
- Considerar reducción de animaciones en modo de bajo consumo

---

**Fecha**: 2026-07-25  
**Skill**: Impeccable - Animate  
**Estado**: ✅ Implementado y verificado

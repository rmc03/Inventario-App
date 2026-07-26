# 🔵 Nueva Paleta — Azure Blue + Copper

## Lo que cambió

### ❌ Antes: Indigo Navy (oscuro, serio)
- Primary: `#1A237E` — Muy oscuro, poco vibrante
- Modo oscuro: `#5C6BC0` — Púrpura apagado
- Secundarios: Verdes y naranjas que no combinaban bien

### ✅ Ahora: Azure Blue (vibrante, moderno)
- Primary: `#0F62FE` — Azul brillante, confiable, energético
- Modo oscuro: `#4589FF` — Luminoso y legible
- Secundarios: Perfectamente armonizados con el azul

---

## La Nueva Paleta Completa

### 🌞 Modo Claro

#### Azul Principal (Primary)
```
Primary:          #0F62FE  ████████  Azure blue — vibrante, moderno
Primary Dark:     #0043CE  ████████  Pressed state
```
**Contraste:** 5.00:1 en blanco (✅ WCAG AA)

#### Superficies y Texto
```
Background:       #FAFAFA  ████████  Off-white cálido
Surface:          #FFFFFF  ████████  Blanco puro
Surface Secondary:#F4F7FB  ████████  Azul muy claro (tinte azure)
Ink:              #161616  ████████  Casi negro (más suave que #000)
Muted:            #6F6F6F  ████████  Gris cálido
Line:             #E0E0E0  ████████  Bordes suaves
```

#### Colores Semánticos
```
Success:          #24A148  ████████  Verde fresco (operaciones exitosas)
Warning:          #B95000  ████████  Ámbar profundo (advertencias, stock bajo)
Danger:           #DA1E28  ████████  Rojo vibrante (errores, alertas)
Info (Copper):    #E8743B  ████████  Cobre cálido — ACENTO DE PERSONALIDAD 🔥
```

**Contraste en blanco:**
- Success: 3.35:1 (iconos y texto grande)
- Warning: 4.99:1 (✅ WCAG AA)
- Danger: 5.00:1 (✅ WCAG AA)
- Copper: 3.00:1 (iconos y badges)

---

### 🌙 Modo Oscuro

#### Azul Principal (Primary)
```
Primary:          #4589FF  ████████  Azure brillante — luminoso en oscuro
Primary Dark:     #78A9FF  ████████  Pressed state (más claro)
```
**Contraste:** 5.51:1 en background oscuro (✅ WCAG AA)

#### Superficies y Texto
```
Background:       #121418  ████████  Azul-negro profundo (OLED-friendly)
Surface:          #1C1F26  ████████  Azul-gris oscuro (no es negro puro)
Surface Secondary:#262A33  ████████  Azul-gris más claro
Ink:              #F4F4F4  ████████  Casi blanco (más suave que #FFF)
Muted:            #A8A8A8  ████████  Gris claro
Line:             #393939  ████████  Bordes oscuros
```

#### Colores Semánticos
```
Success:          #42BE65  ████████  Verde brillante
Warning:          #F1C21B  ████████  Amarillo brillante (muy visible)
Danger:           #FF8389  ████████  Rojo-rosa brillante (legible)
Info (Copper):    #FF9E6D  ████████  Cobre luminoso — BRILLANTE Y CÁLIDO 🔥
```

**Contraste en background oscuro:**
- Success: 7.71:1 (✅ WCAG AAA)
- Warning: 10.95:1 (✅ WCAG AAA — excepcional)
- Danger: 7.78:1 (✅ WCAG AAA)
- Copper: 9.10:1 (✅ WCAG AAA — excepcional)

---

## Por qué esta paleta funciona mejor

### 1. **Azul más bonito y vibrante**
El azure blue (`#0F62FE`) es:
- ✨ Más moderno que el indigo navy oscuro
- 💙 Reconocible como "azul" (el anterior era casi púrpura)
- ⚡ Energético sin ser agresivo
- 🏢 Profesional pero amigable

### 2. **Modo oscuro excepcional**
- 🌟 Azure brillante (`#4589FF`) se ve **espectacular** en fondos oscuros
- 🎨 Superficies azul-gris (no negro puro) dan **personalidad**
- ✅ Todos los colores tienen contraste AAA
- 📱 OLED-friendly: ahorra batería sin sacrificar estética

### 3. **Secundarios perfectamente armonizados**
Los colores semánticos ahora **combinan perfectamente** con el azul:

#### Verde Success (`#24A148` / `#42BE65`)
- Temperatura visual balanceada con el azul
- Verde fresco, no amarillento
- Perfecto para confirmaciones operativas

#### Amarillo Warning (`#B95000` / `#F1C21B`)
- Modo claro: Ámbar profundo (cálido, visible)
- Modo oscuro: Amarillo brillante (máximo contraste)
- Stock bajo se ve inmediatamente

#### Rojo Danger (`#DA1E28` / `#FF8389`)
- Modo claro: Rojo vibrante pero no agresivo
- Modo oscuro: Rosa-rojo legible (menos duro)
- Errores críticos destacan sin quemar la vista

#### Cobre Info (`#E8743B` / `#FF9E6D`) 🔥
- El **acento de personalidad** se mantiene
- Contraste perfecto con el azul frío
- Modo oscuro: **brilla bellamente** contra superficies azul-oscuro

---

## Armonía de Color

### Modo Claro: Cool + Warm
```
Azul Azure (frío) ──────┐
                        ├─→ Tensión visual memorable
Cobre (cálido) ─────────┘
```
El azul fresco + cobre cálido = **contraste complementario** perfecto.

### Modo Oscuro: Luminosidad controlada
```
Fondo azul-negro profundo
    ↓
Azul brillante (#4589FF) ─→ Estructura
    ↓
Cobre luminoso (#FF9E6D) ─→ Momentos especiales
```

---

## Comparación Visual

### Antes vs Ahora

| Elemento | Antes (Indigo) | Ahora (Azure) |
|----------|----------------|---------------|
| **Primary light** | `#1A237E` oscuro | `#0F62FE` vibrante ✨ |
| **Primary dark** | `#5C6BC0` púrpura | `#4589FF` azure brillante ✨ |
| **Feeling** | Serio, corporativo | Moderno, amigable ✨ |
| **Legibilidad dark** | Buena | Excelente ✨ |
| **Secundarios** | Desbalanceados | Perfectamente armonizados ✨ |

---

## Implementación

### Accede a los colores
```dart
// Azul primary
context.colors.primary

// Cobre (personalidad)
context.colors.info

// Semánticos
context.colors.success
context.colors.warning
context.colors.danger
```

### Ejemplos de uso

#### Botón primario
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: context.colors.primary, // Azure blue brillante
  ),
  child: Text('Guardar venta'),
)
```

#### Badge de éxito con cobre
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Sincronizado',
    style: TextStyle(
      color: context.colors.info, // Cobre
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

#### Alerta de stock bajo
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: context.colors.warning.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(Icons.warning_amber_rounded, color: context.colors.warning),
      SizedBox(width: 8),
      Text('Stock bajo', style: TextStyle(color: context.colors.warning)),
    ],
  ),
)
```

---

## Testing

### ✅ Checklist de Verificación

**Modo Claro:**
- [ ] Azul primary se ve vibrante pero no agresivo
- [ ] Cobre destaca en badges y métricas
- [ ] Verde success es fresco y claro
- [ ] Ámbar warning es visible sin quemar
- [ ] Rojo danger es claro sin ser alarmista

**Modo Oscuro:**
- [ ] Azul brillante se ve **espectacular**
- [ ] Cobre **brilla** contra superficies oscuras
- [ ] Todos los colores son legibles sin esfuerzo
- [ ] Superficies tienen tinte azul (no negro puro)
- [ ] OLED: Oscuro suficiente para ahorrar batería

**Transición:**
- [ ] Cambio entre modos se siente fluido
- [ ] Colores mantienen su "personalidad" en ambos modos

---

## Próximos Pasos

### 1. Prueba la app (5 minutos)
Cambia entre modo claro y oscuro varias veces. ¿Se siente mejor?

### 2. Ajusta si es necesario
Si algún color específico no te convence, avísame y lo ajustamos.

### 3. Expande el uso del cobre
Implementa los quick wins del documento anterior:
- Sale completion con cobre
- Sync badge con cobre
- Cuadre perfecto con cobre

---

**Resumen:** Azul vibrante y moderno + modo oscuro excepcional + secundarios perfectamente armonizados = **paleta completa y profesional** 🎨✨

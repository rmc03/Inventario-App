# Design System

<!-- impeccable:design-schema 1 -->

## Visual Identity

**Brand Thesis:** "Clean Focus" — Fondos neutros con tintes de personalidad donde el color primario destaca en momentos estratégicos. Limpio, funcional, sin distracciones.

**Color Philosophy:** 
- **6 temas con personalidad propia** — cada uno con su propio "color soul" que se extiende a fondos, bordes y semanticos
- **Neutros teñidos, no grises genéricos** — el tema se siente desde el fondo, no solo en el CTA
- **Dark mode con base única** — cada tema tiene su propio color de fondo oscuro, no todos slate idéntico

## Color System — 6 Temas

Cada tema varía: primary, neutros (background, surfaceSecondary, line, ink) y semánticos (success, warning, danger, info) para crear una identidad visual completa.

### 1. 💼 CORPORATIVO (Indigo) — Profesional, confiable
**Light:** Fondo #F8F9FC (gris azulado frío), cards blancos, bordes #E2E4EB
**Dark:** Fondo #0E0F1A (navy profundo), cards #1A1B2E, índigo #818CF8

```dart
// Light                         // Dark
primary:      #4F46E5           #818CF8
ink:          #1A1A2E           #EEEEF4
muted:        #6B7280           #8B8DA8
line:         #E2E4EB           #2D2E4A
surface:      #FFFFFF           #1A1B2E
surfaceSec:   #EEF0F6           #12132A
background:   #F8F9FC           #0E0F1A
success:      #10B981           #34D399
warning:      #F59E0B           #FBBF24
danger:       #EF4444           #F87171
info:         #8B5CF6           #A78BFA
```

### 2. 💰 PROSPERIDAD (Emerald) — Fresco, natural
**Light:** Fondo #F8FAF7 (verde tenue), bordes #E2EBE5, ink #1A2E1A
**Dark:** Fondo #0F1A14 (bosque profundo), cards #1A2E22, esmeralda #34D399

```dart
// Light                         // Dark
primary:      #059669           #34D399
ink:          #1A2E1A           #EEF4F0
muted:        #6B7280           #8BA898
line:         #E2EBE5           #2A4A38
surface:      #FFFFFF           #1A2E22
surfaceSec:   #ECF7F0           #0F1A14
background:   #F8FAF7           #0F1A14
success:      #059669           #6EE7B7
warning:      #D97706           #FBBF24
danger:       #DC2626           #F87171
info:         #0891B2           #22D3EE
```

### 3. ⚡ ENERGÍA (Sunset) — Cálido, dinámico
**Light:** Fondo #FEFAF7 (melón tenue), bordes #F0E6DE, ink #2E1A1A
**Dark:** Fondo #1A120E (carbón cálido), cards #2E221A, naranja #FB923C

```dart
// Light                         // Dark
primary:      #EA580C           #FB923C
ink:          #2E1A1A           #F4F0EE
muted:        #6B7280           #A89888
line:         #F0E6DE           #4A3A2A
surface:      #FFFFFF           #2E221A
surfaceSec:   #FFF5ED           #1A120E
background:   #FEFAF7           #1A120E
success:      #059669           #34D399
warning:      #D97706           #FBBF24
danger:       #DC2626           #F87171
info:         #DB2777           #F472B6
```

### 4. 🛡️ CONFIANZA (Ocean) — Calmado, seguro
**Light:** Fondo #F7FAFC (cielo tenue), bordes #DEE7F0, ink #1A1A2E
**Dark:** Fondo #0E141A (océano profundo), cards #1A2632, celeste #38BDF8

```dart
// Light                         // Dark
primary:      #0284C7           #38BDF8
ink:          #1A1A2E           #EEF0F4
muted:        #6B7280           #889EA8
line:         #DEE7F0           #2A3E4A
surface:      #FFFFFF           #1A2632
surfaceSec:   #EDF4FA           #0E141A
background:   #F7FAFC           #0E141A
success:      #059669           #34D399
warning:      #D97706           #FBBF24
danger:       #DC2626           #F87171
info:         #0891B2           #22D3EE
```

### 5. 💡 INNOVACIÓN (Amethyst) — Creativo, visionario
**Light:** Fondo #FAF8FC (lavanda tenue), bordes #E8E2F0, ink #1E1A2E
**Dark:** Fondo #14101A (púrpura profundo), cards #221A32, violeta #A78BFA

```dart
// Light                         // Dark
primary:      #7C3AED           #A78BFA
ink:          #1E1A2E           #F2EEF6
muted:        #6B7280           #9E88B0
line:         #E8E2F0           #3A2A4A
surface:      #FFFFFF           #221A32
surfaceSec:   #F3EEF8           #14101A
background:   #FAF8FC           #14101A
success:      #059669           #34D399
warning:      #D97706           #FBBF24
danger:       #DC2626           #F87171
info:         #7C3AED           #C4B5FD
```

### 6. 🎯 IMPACTO (Ruby) — Audaz, decidido
**Light:** Fondo #FEF8F8 (rosa tenue), bordes #F0E2E2, ink #2E1A1A
**Dark:** Fondo #1A0E0E (burdeos profundo), cards #2E1A1A, rojo #F87171

```dart
// Light                         // Dark
primary:      #DC2626           #F87171
ink:          #2E1A1A           #F4EEEE
muted:        #6B7280           #A88888
line:         #F0E2E2           #4A2A2A
surface:      #FFFFFF           #2E1A1A
surfaceSec:   #FEEEEE           #1A0E0E
background:   #FEF8F8           #1A0E0E
success:      #059669           #34D399
warning:      #D97706           #FBBF24
danger:       #DC2626           #FCA5A5
info:         #DB2777           #F472B6
```

## Dark Mode Design

### Filosofía: Cada tema, su propia noche
A diferencia de un enfoque "one dark fits all", cada tema tiene su propia base oscura:
- **Corporativo:** Navy profundo (#0E0F1A) — serio, profesional
- **Prosperidad:** Bosque (#0F1A14) — natural, orgánico
- **Energía:** Carbón cálido (#1A120E) — acogedor, vibrante
- **Confianza:** Océano (#0E141A) — profundo, calmado
- **Innovación:** Púrpura (#14101A) — creativo, misterioso
- **Impacto:** Burdeos (#1A0E0E) — intenso, dramático

### Principios comunes (aplican a todos los temas):
- Sin negro puro (#000000) — siempre fondos con carácter
- Color primario brilla más en dark mode (variante más clara)
- Neutros se tiñen sutilmente del tono del tema
- Glow estratégico en elementos hero (stats, headers)
- Bordes visibles pero sutiles

## Dark Mode Enhancements (per-theme day headers)
Los day headers en Movimientos usan el color primario del tema activo como fondo sólido con texto blanco.

## Typography

**Family:** Outfit — modern geometric sans-serif with distinctive character. Excellent Spanish support (ñ, accents). Bundled as asset fonts (works offline).
**Fallback:** San Francisco (iOS) / Roboto (Android)
**Scale:** Material Design 3 type scale with Apple HIG alignment

```
Display Large:  34pt/Bold   (headlines, hero moments)
Display Medium: 22pt/Bold   (section titles)
Headline Large: 34pt/Bold   (screen headers)
Headline Medium:22pt/Bold   (section titles)
Title Large:    20pt/SemiBold (screen titles)
Title Medium:   17pt/SemiBold (card headers)
Body Large:     17pt/Regular (primary text)
Body Medium:    13pt/Regular (secondary text, labels)
Body Small:     11pt/Regular (captions, metadata)
Label Large:    17pt/SemiBold (buttons, CTAs)
Label Medium:   13pt/Medium  (chips, badges)
Label Small:    11pt/Medium  (fine print)
```

**Bold Text Support:** Accessibility setting increases all weights by 100-200.

## Spacing & Layout

**Base Unit:** 4px (0.25rem)
**Scale:** xs(4) | sm(8) | md(12) | lg(16) | xl(20) | xxl(32)

**Safe Areas:** Respects iOS notch, Dynamic Island, Android cutouts
**Max Width:** 800px center constraint on tablets/desktop

## Radii

```dart
pill: 9999px        // Pills, tags, infinite radius
lg: 16px            // Large cards, modals
md: 12px            // Standard cards, buttons
sm: 8px             // Small elements, badges
xs: 4px             // Minimal rounding
```

## Elevation & Shadows

### Light Mode
```dart
subtle: y:2 blur:4 alpha:0.06    // Cards, surfaces
medium: y:4 blur:12 alpha:0.08   // Elevated elements
strong: y:8 blur:24 alpha:0.12   // Modals, overlays
```

### Dark Mode — BOLDER
```dart
cards: elevation:2 color:primary.alpha(0.15)   // Subtle blue glow
fab: elevation:8 (doubled from light)           // More prominent
glow: blur:16-32 alpha:0.1-0.25                // Color-matched shadows on hero elements
```

## Motion & Animation

**Philosophy:** Native timing, GPU-accelerated transforms, respects system Reduce Motion

**Timings:**
```dart
feedback: 150ms      // Táctil, instant response
transition: 300ms    // Segmented controls, tabs
entrance: 400ms      // Content reveal, fade-ins
stagger: 80ms        // Sequential item delays
count: 800ms         // Hero stat number animations
```

**Curves:**
- `easeOutCubic`: Standard transitions, entrance
- `easeOutBack`: Hero stat scale-in (overshoot for delight)
- `elasticOut`: Icon entrances (playful bounce)

**Patterns:**
- Fade + Slide up: Content entrance
- Scale + Fade: Hero cards
- Staggered entrance: List items with 60-80ms delay
- Number counting: 0 → value with easeOutCubic

## Components — Dark Mode Specifics

### Hero Stats Cards
- Gradient background `surface → surfaceSecondary`
- Border: icon color @ alpha 0.15, width 1.5px
- Icon container: radial gradient + color glow shadow
- Main value: icon color, 34pt bold
- Card shadow: dual-layer (blur 16 + 32) with icon color

### Segmented Button (Period Selector)
- Container: gradient background with primary @ alpha 0.08-0.04
- Border: primary @ alpha 0.15, width 1px
- Padding: 4px around button group

### Day Headers (Movimientos)
- **Fondo:** Azul sólido (#5B9FFF) — el momento héroe
- **Texto:** Blanco puro para máximo contraste
- **Shadow:** Azul @ alpha 0.35, blur 24px
- **Líneas laterales:** Gris neutro con gradiente de fade

### Empty States
- Circle border: 3.5px gris neutro o azul según contexto
- Shadow: azul @ alpha 0.30, blur 32px
- Icon alpha: 0.75 para visibilidad

### Cards Generales
- Background: gris surface neutro (#1F1F1F)
- Elevation: 2 con shadowColor de primary solo en cards destacados
- Sin gradientes de fondo — limpio como WhatsApp

## Accessibility

✅ **WCAG AA Compliance:**
- Text contrast ratios meet AA standard in both modes
- Dark mode uses near-white (#FAFAFA) for high contrast
- Interactive elements: 44×44pt minimum touch target (iOS) / 48×48dp (Android)

✅ **Dynamic Type:** All text uses sp/pt units and scales with system font size
✅ **Bold Text:** Accessibility setting supported, increases all weights
✅ **Reduce Motion:** Animations honor system preference (crossfade fallback)
✅ **Screen Readers:** Semantic labels on all interactive elements

## Platform Conformance

### iOS (HIG)
- Safe area insets respected (notch, Dynamic Island, home indicator)
- SF Symbols for iconography
- Edge-swipe back gesture preserved
- System materials for blur/translucency
- Dark Mode: first-class appearance

### Android (Material 3)
- Window insets (status bar, nav bar, cutouts)
- Material components (buttons, FAB, snackbars, sheets)
- Predictive Back gesture honored
- Tonal elevation + optional shadow
- Dynamic Color optional (static scheme fallback)

## Usage Principles

1. **Cada tema tiene personalidad desde el fondo** — no solo el CTA cambia, también los neutros y semánticos
2. **El color primario es estratégico** — solo en headers importantes, stats, y elementos interactivos clave
3. **Sin gradientes de fondo** — backgrounds siempre sólidos, pero con el tinte del tema
4. **Glow es purposeful** — solo en cards de estadísticas hero y headers destacados
5. **Dark mode no es genérico** — cada tema tiene su propia base oscura con carácter único

## Anti-Patterns

❌ Don't use pure black (#000000) backgrounds — use themed dark gray/color
❌ Don't use identical neutrals across themes — each theme tints its grays
❌ Don't use the same dark background for all themes — each needs its own night
❌ Don't use gradients on card backgrounds — only solid colors
❌ Don't apply glow to every element — reserve for hero moments (headers, hero stats)
❌ Don't use gradients on text — only on backgrounds and icon containers
❌ Don't override platform navigation patterns

---

**Last Updated:** 2026-07-28  
**Design Direction:** Bolder — 6 themes, each with distinct color soul  
**Conformance:** iOS HIG + Material Design 3 Motion Guidelines

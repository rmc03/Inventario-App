# Design System

<!-- impeccable:design-schema 1 -->

## Visual Identity

**Brand Thesis:** "Clean Focus" — Fondo gris suave (no negro puro) donde el azul destaca en momentos estratégicos. Limpio, funcional, sin distracciones.

**Color Philosophy:**
- **Light Mode:** Azure blue + copper accent — fresh, professional, memorable
- **Dark Mode:** Soft gray + electric blue hero accent. "Clean focus" — minimal, clear, readable

## Color System

### Light Mode
```dart
primary: #0F62FE        // 🔥 Azure blue (IBM Carbon) — vibrante, moderno, confiable, MEMORABLE
primaryDark: #0043CE    // Pressed state (azure profundo)
ink: #161616            // Near-black text (softer than pure black)
muted: #6F6F6F          // Warm gray (secondary content)
line: #E0E0E0           // Light border
surface: #FFFFFF        // Card surface (white)
surfaceSecondary: #F0F2F5  // Neutral gray-blue (subtle)
background: #F5F5F5     // Neutral gray scaffold
success: #24A148        // Fresh green (operational success)
warning: #B95000        // Deep amber (caution)
danger: #DA1E28         // Vibrant red (errors, stock alerts)
info: #E8743B           // 🔥 Warm copper — PERSONALITY ACCENT
```

### Dark Mode — WhatsApp-Inspired Clean Edition
```dart
primary: #5B9FFF        // 🔥 Electric azure — HERO ACCENT (más vibrante que índigo)
primaryDark: #85B8FF    // Pressed state (brighter azure)
ink: #E5E5E5            // Soft white text (easy on eyes)
muted: #999999          // Medium gray for secondary
line: #2A2A2A           // Subtle dark border
surface: #1F1F1F        // Card surface (slightly lighter)
surfaceSecondary: #2A2A2A  // Slightly lighter gray
background: #111111     // 🔥 WhatsApp-style background (matches #0E0E0E vibe)
success: #3FD372        // Neon green
warning: #FFD23F        // Bright amber
danger: #FF6B7A         // Hot pink-red
info: #FF8B5A           // Vibrant copper
```

**Philosophy:** 
- **Azul Azure con personalidad** — no genérico, vibrante, memorable
- **Fondo como WhatsApp** (#111111) — oscuro pero no negro puro
- **AppBar oscuro** en dark mode (como WhatsApp) con texto claro
- AppBar azul solo en light mode (más colorido y vibrante)
- Diseño limpio sin brillos innecesarios

## Dark Mode Enhancements (WhatsApp-inspired)

### Filosofía: Grises Neutros + Azul Héroe
Como WhatsApp usa verde sobre gris oscuro, esta app usa **azul eléctrico** como color héroe sobre grises neutros limpios:
- **Backgrounds:** Grises neutros (#0F0F0F, #1F1F1F, #2A2A2A) sin tintes de color
- **Azul es el héroe:** Solo aparece en momentos estratégicos que requieren atención
- **No gradientes de color en backgrounds** — solo en íconos y elementos específicos

### Headers con Fondo Azul
Los day headers en Movimientos usan **fondo azul sólido** (#5B9FFF) con texto blanco, creando un punto focal claro:
- Sombra azul dramática (alpha 0.35, blur 24px)
- Sin border (el color sólido es suficiente statement)
- Líneas laterales en gris neutro (no azul)

### Hero Stats Cards
Diseño minimalista con acentos de color estratégicos:
- **Background:** Gris surface neutro (#1F1F1F), sin gradientes
- **Border:** Color del ícono @ alpha 0.15 para énfasis sutil
- **Ícono:** Gradiente radial del color + shadow glow
- **Valor numérico:** Color vibrante del ícono (success/info)
- **Card shadow:** Glow de color con dual-layer (blur 16+32px)

### Glow Effects
Elementos clave tienen glow sutil en modo oscuro para crear énfasis visual:
- **Hero Stats Cards:** Sombras de color en el tono del ícono (success, info) con blur radius de 16-32px
- **Day Headers:** Sombra azul eléctrica con alpha 0.25, blur 20px
- **Empty States:** Círculos con sombra primaria más pronunciada
- **Cards:** Elevation 2 con shadowColor de primary.withAlpha(0.15)

### Borders y Líneas
Borders sutiles en gris neutro, excepto cuando se usa color para énfasis:
- Border width: 1.5px estándar
- Color borders: solo en elementos que necesitan destacar (cards con glow)
- Line dividers: gris neutro (#3A3A3A), no gradientes

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

1. **Dark mode es limpio y minimalista** — grises neutros como WhatsApp, azul como héroe
2. **El azul es estratégico** — solo en headers importantes, stats, y elementos interactivos clave
3. **Sin gradientes de fondo** — backgrounds siempre sólidos en grises neutros
4. **Glow es purposeful** — solo en cards de estadísticas hero y headers destacados
5. **Borders en gris neutral** — excepto cuando se necesita énfasis con color (alpha 0.15)

## Anti-Patterns

❌ Don't use pure black (#000000) backgrounds — use neutral dark gray (#0F0F0F)
❌ Don't add blue tints to grays — keep backgrounds neutral like WhatsApp
❌ Don't use gradients on card backgrounds — only solid grays
❌ Don't apply glow to every element — reserve for hero moments (headers, hero stats)
❌ Don't use gradients on text — only on backgrounds and icon containers
❌ Don't override platform navigation patterns

---

**Last Updated:** 2026-07-25  
**Design Direction:** Bolder — amplified saturation, enhanced depth, electric confidence  
**Conformance:** iOS HIG + Material Design 3 Motion Guidelines

# 🔥 Copper Personality — Inventario App

## Executive Summary

Your app already has a distinctive color personality: **Indigo Navy + Copper**. The copper accent (`colors.info`) creates memorable moments in an operational interface, appearing at moments of completion, success, and warmth.

**Current state:** Copper exists and is used strategically in some places (inventory additions, unit counts).

**Opportunity:** Expand copper usage consistently across success moments to strengthen the app's emotional signature.

---

## The Color Palette

### Light Mode
- **Primary (Indigo):** `#1A237E` — Structure, authority, navigation
- **Copper Accent:** `#D4653B` — Personality, warmth, completion 🔥
- **Surfaces:** Cool off-white (`#F5F6FA`) + white cards

### Dark Mode
- **Primary (Indigo):** `#5C6BC0` — Lighter for legibility
- **Copper Accent:** `#FF9A6C` — Bright, luminous warmth 🔥
- **Surfaces:** Navy-toned darks (not pure black) — OLED-friendly with personality

---

## Delight Thesis

**"Warmth in reliability"**

In an offline-first app for small shop owners, copper signals:
- Your work is saved
- The sync succeeded
- The register balances
- The inventory arrived
- The milestone is reached

Copper = the app showing human warmth in operational moments.

---

## Where Copper Lives

### ✅ Already Using Copper Well
1. **Inventory additions** — Movement cards with copper accent
2. **Unit counts** — Pills showing quantity metrics
3. **Dashboard progress bars** — Second-ranked products

### 🎯 Expand Copper Here
1. **Sale completions** — Confirmation with copper badge/SnackBar
2. **Sync success** — "Sincronizado" badge when data syncs
3. **Cash register balance** — Copper border when cuadre is perfect
4. **Milestones** — 100th sale celebration with copper
5. **Empty states** — "Añade tu primer producto" CTA with copper accent

---

## Accessibility & Contrast

### Light Mode (`#D4653B`)
- **3.67:1** on white — ✅ Good for icons 16px+, headings 18pt+
- **Not for body text** — Use only for accents, badges, headings

### Dark Mode (`#FF9A6C`)
- **9.00:1** on dark background — ✅ AAA Excellent
- **Can be used for all text sizes** — Exceptional contrast

---

## Implementation Quick Start

### 1. Copper Badge Pattern
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.check_circle_rounded, size: 14, color: context.colors.info),
      SizedBox(width: 6),
      Text('Guardado', style: TextStyle(color: context.colors.info, fontWeight: FontWeight.w600)),
    ],
  ),
)
```

### 2. Copper Icon Accent
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.12),
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.inventory_2_outlined, color: context.colors.info, size: 24),
)
```

### 3. Copper Success SnackBar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: context.colors.info.withValues(alpha: 0.95),
    content: Row(
      children: [
        Icon(Icons.check_circle_rounded, color: Colors.white),
        SizedBox(width: 12),
        Text('Venta guardada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ],
    ),
  ),
);
```

---

## Rules for Copper

### ✅ DO Use Copper For:
- Sale completions
- Sync success
- Inventory additions
- Cash register balance
- Unit counts and metrics
- Milestones and achievements

### ❌ DON'T Use Copper For:
- Error states (use `danger` red)
- Warnings (use `warning` orange)
- Neutral operations (use `ink` or `muted`)
- Primary navigation (use `primary` indigo)
- Every card border (overuse kills personality)

---

## Motorcycle Heritage

The indigo + copper pairing references classic motorcycle brand aesthetics:
- **Triumph:** Navy + racing orange
- **Ducati:** Red + black with warm undertones
- **Vintage racing:** Cool structure + warm speed

This isn't decoration — it's operational craft rooted in the product's domain.

---

## Next Steps

### Quick Wins (30 minutes)
1. Update sale completion to use copper SnackBar
2. Add copper sync badge to app bar when online
3. Standardize unit count pills to always use copper

### Delight Enhancements (2 hours)
1. Copper border for balanced cash register (cuadre perfecto)
2. First sale celebration with copper
3. Milestone badges (100th sale, etc.)

### Test
- Verify contrast in both light and dark modes
- Test on OLED screens (dark mode copper should glow, not burn)
- Ensure copper feels warm and reliable, not decorative

---

## Documentation

Full documentation created in `.impeccable/`:
1. **COLOR-PERSONALITY.md** — Complete guide with delight thesis
2. **color-swatches.md** — Palette reference for both modes
3. **examples/copper-delight-examples.md** — Code patterns and implementations

---

## Theme Changes Made

Updated `lib/core/theme/app_theme.dart`:
- **Light copper:** `#C75B39` → `#D4653B` (slightly adjusted for better visibility)
- **Dark copper:** `#E87A5A` → `#FF9A6C` (more luminous on navy backgrounds)
- Added delight thesis comments in theme file

---

**Version:** 1.0  
**Date:** 2026-07-25  
**Maintained by:** Impeccable Design System

---

## The One-Sentence Summary

**Copper is your app's signature — use it when the system confirms work is safe, complete, or successful, creating warmth in reliability.**

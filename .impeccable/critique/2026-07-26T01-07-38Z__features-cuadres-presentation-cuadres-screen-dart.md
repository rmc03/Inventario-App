---
target: pantalla de cuadres que ve el admin
total_score: 21
max_score: 36
na_heuristics: 10
p0_count: 0
p1_count: 3
p2_count: 2
timestamp: 2026-07-26T01-07-38Z
slug: features-cuadres-presentation-cuadres-screen-dart
---
# Critique: Pantalla de Cuadres (Admin)

Method: dual-agent (A: general · B: general)

---

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No loading states, no success feedback after approve/reject |
| 2 | Match System / Real World | 3 | Domain terms correct, but approval dialog uses internal system language |
| 3 | User Control and Freedom | 2 | No undo for approve/reject, no cancel-able in-progress state |
| 4 | Consistency and Standards | 3 | Local _EstadoBadge inconsistent with shared EstadoBadge (icons, semantics) |
| 5 | Error Prevention | 2 | Reject requires comment (good), but approve has no summary of what's being signed off |
| 6 | Recognition Rather Than Recall | 3 | Toggle + ExpansionTile good, but list lacks totals for triage |
| 7 | Flexibility and Efficiency of Use | 2 | No search, no filter (disabled), no bulk actions, no sort |
| 8 | Aesthetic and Minimalist Design | 3 | Detail screen well-composed; list screen is bare-bones; dead menu item |
| 9 | Error Recovery | 1 | Zero error states, silent catch blocks, no retry mechanisms |
| 10 | Help and Documentation | n/a | Admin panel for shop owner; not applicable |
| **Total** | | **21/36** | **Acceptable (58%)** |

Heuristic 10 scored n/a. Applicable maximum: 36.

---

## Design Specificity Verdict

**Partially grounded.** The detail screen earns specificity through its domain-driven composition: hero total formatted as Latin American currency with tabular figures, the Resumen/Productos toggle reflecting two distinct mental models of a cash register closing, employee avatar initials, the _ComentarioJefe box, and the high-stakes approve/reject bar with consequence warnings. This screen could not be swapped into another admin panel without losing meaning.

The list screen is generic. It is a flat list of Card > ListTile with date, name, and a status badge — the same composition used by any CRUD list. No totals, no urgency signals, no grouping by status or date. The design does not reflect that this is a cash register closing review queue where pending items demand attention and approved items are historical artifacts.

**Deterministic scan:** The CLI detector returned 0 findings (Flutter/Dart not supported by the web-focused detector). Manual advisory findings: ~15 unique patterns across 40+ locations — primarily spacing-consistency (raw numbers instead of AppSpacing tokens), token-mismatch (hardcoded alpha/radius values), and accessibility gaps (missing Semantics on interactive widgets). Browser visualization skipped: Flutter native app.

---

## Overall Impression

The detail screen is solid — the hero KPIs, the toggle, and the rejection flow are genuinely well-designed for a financial review task. The list screen is the weak link: it's a flat, information-poor surface that forces the admin into a tedious tap-to-inspect workflow. The biggest opportunity is transforming the list from a passive archive into an actionable triage surface — pending items visually elevated, financial info visible, and batch actions available.

---

## What's Working

1. **Hero KPI pattern** (cuadre_detalle_screen.dart:339-396). The large headlineLarge total with tabular figures, the "Total del cuadre" label, and two _MetricCard widgets with colored icon-in-filled-container create an immediately scannable financial summary. This is exactly what the admin needs.

2. **Rejection flow** (cuadre_detalle_screen.dart:846-914). Mandatory comment with inline error validation, StatefulBuilder for live error clearing, danger-colored button, clear consequence text, and haptic differentiation. A model rejection pattern.

3. **Resumen/Productos toggle** (cuadre_detalle_screen.dart:105-130). Clean progressive disclosure with AnimatedContainer, smooth 200ms transition, and shared total row. Reduces cognitive load by separating two mental models of the same data.

---

## Priority Issues

### [P1] No empty state on the list screen
**What:** When cuadres is empty, the list renders a blank Scaffold with AppBar. The detail screen has _EmptyDetalle but the list does not.
**Why it matters:** The admin sees nothing — no explanation, no guidance, no call to action. On first use or after data clearing, the screen is broken.
**Fix:** Add an empty state widget matching _EmptyDetalle's pattern: icon + title + subtitle, centered in the ListView.
**Suggested command:** $impeccable polish

### [P1] No post-action feedback after approve/reject
**What:** After approving or rejecting, the admin is immediately navigated to the list via context.go. No snackbar, no toast, no confirmation message. The haptic fires but is ephemeral.
**Why it matters:** The admin must visually verify the status badge changed. If they don't notice which card they just acted on, they may repeat the action or feel uncertain.
**Fix:** Show a SnackBar with confirmation text ("Cuadre aprobado" / "Cuadre rechazado") after navigation. Use ScaffoldMessenger.
**Suggested command:** $impeccable delight

### [P1] List items show zero financial information
**What:** Each ListTile at cuadres_screen.dart:61-69 shows date + employee name + status badge. The total amount is absent.
**Why it matters:** The admin must tap into every cuadre to see its total. This turns triage into a sequential, high-effort process. A pending cuadre with $5 vs $500 should be triaged differently.
**Fix:** Add the cuadre.valorTotal as a trailing or secondary trailing element. Use tabular figures and primary color to match the detail screen's financial language.
**Suggested command:** $impeccable layout

### [P2] Local _EstadoBadge is inaccessible and inconsistent
**What:** The list screen's _EstadoBadge (cuadres_screen.dart:82-111) is a plain text badge with no Semantics wrapper and no icon. The shared EstadoBadge has Semantics(label: 'Estado: ${estado.label}') and a status icon.
**Why it matters:** Screen readers cannot determine cuadre status from the list. The visual inconsistency between list and detail badges breaks the design system.
**Fix:** Replace the local _EstadoBadge with the shared EstadoBadge from estado_badge.dart.
**Suggested command:** $impeccable polish

### [P2] _ToggleOption uses GestureDetector with no accessibility support
**What:** The toggle between Resumen/Productos at cuadre_detalle_screen.dart:470 uses GestureDetector — no semantics, no focus, no keyboard support, no ink ripple.
**Why it matters:** Screen reader users cannot switch between the two views. The toggle is completely invisible to assistive technology.
**Fix:** Replace GestureDetector with InkWell, wrap in Semantics(button: true, selected: _mostrarProductos). Add FocusNode for keyboard navigation.
**Suggested command:** $impeccable harden

---

## Persona Red Flags

### Alex (Power User)
- **No search or filter.** With weeks of cuadres, finding a specific one is a linear scan. The disabled "Filtrar por fecha" makes this worse — Alex knows it exists but can't use it.
- **No bulk approve/reject.** If Alex reviews 5 cuadres a day, they must open → review → approve → back → repeat ×5. No batch operation.
- **No financial info on list cards.** Alex can't triage by scanning — they must tap every card to assess.

### Sam (Accessibility-Dependent)
- **_ToggleOption invisible to screen readers.** The GestureDetector provides no semantic information. Sam cannot switch between Resumen and Productos.
- **List _EstadoBadge has no Semantics.** Sam cannot determine cuadre status from the list.
- **Confirmation dialogs lack semantic structure.** The AlertDialog may not clearly announce the destructive nature of the reject action.

### Casey (Mobile User)
- **Action bar can be below the fold.** On a small phone, header + KPIs + toggle + first venta card can push approve/reject off-screen. The admin must scroll to act.
- **ExpansionTile touch targets.** tilePadding with vertical: 4 creates small hit areas. Borderline for WCAG 2.5.5 minimum.

---

## Minor Observations

- _mostrarProductos state resets on every navigation. If the admin prefers Productos view, they must re-toggle every time.
- compactDateFormatter shows dd/MM/yyyy without day of week. Adding "lun 25/07/2026" would help identify cuadres faster.
- confirmarCuadre silently catches exceptions with empty catch blocks. If the SQLite write fails, the admin has no idea.
- _ComentarioJefe uses danger styling regardless of cuadre estado — an approved cuadre with a comment still appears in a red danger box.
- 915 lines in cuadre_detalle_screen.dart; consider extracting _buildResumenView / _buildProductosView into separate widget classes.

---

## Questions to Consider

1. If the admin's primary job is to approve or reject pending cuadres, why is there no visual signal of pending count — no badge on the navigation tab, no filter chip, no "3 pendientes" indicator?
2. The list shows all cuadres with identical visual weight. Why? A pending cuadre from today demands action; an approved one from last month is archive noise. Shouldn't the list group by status?
3. What does "approving" actually mean to the admin's mental model? The dialog says "El stock ya fue descontado al registrar las ventas" — so approval is a bureaucratic stamp. Could the UI make this clearer?
4. Both approve and reject are irreversible with no undo. For a system managing real inventory and real money, is a 5-second undo window worth the investment?

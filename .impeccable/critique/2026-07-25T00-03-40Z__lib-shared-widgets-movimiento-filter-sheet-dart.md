---
timestamp: 2026-07-25T00-03-40Z
slug: lib-shared-widgets-movimiento-filter-sheet-dart
---
# Design Critique: Custom Date Sort Filter (Movimientos Screen)

**Target:** `lib/shared/widgets/movimiento_filter_sheet.dart` + `lib/features/movimientos/presentation/movimientos_screen.dart`

**Method:** Dual-agent (A: design review · B: deterministic detector)
**Detector findings:** `[]` — Dart/Flutter has no web-based detection rules; no false positives.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No feedback when date picker is cancelled; partial "Personalizado" state silently shows today's data |
| 2 | Match System / Real World | 3 | Spanish labels are good, but flow fights mental model — open → close → open → pick |
| 3 | User Control and Freedom | 2 | No way to change mind after tapping "Personalizado" without navigating the cancellation gauntlet |
| 4 | Consistency and Standards | 2 | Other filter sheets also auto-close, but the date range flow needs multi-step config — auto-close breaks it |
| 5 | Error Prevention | 1 | Partial state: `rango=personalizado` + no dates exists briefly; `fechaInicio` silently falls back to today |
| 6 | Recognition Rather Than Recall | 2 | "Personalizado" tile doesn't surface previous dates without re-opening the sheet |
| 7 | Flexibility and Efficiency | 1 | Double-open required for multi-filter (tipo + personalizado); no batch config |
| 8 | Aesthetic and Minimalist Design | 3 | Visual design is solid; the problem is interaction architecture, not decoration |
| 9 | Error Recovery | 1 | No recovery path if date picker is dismissed unexpectedly (back gesture) |
| 10 | Help and Documentation | 2 | No explanatory text for what "Personalizado" will do before tapping |
| **Total** | | **19/40** | **Poor** — core interaction flow is broken |

## Design Specificity Verdict

**LLM assessment:** The filter sheet is well-structured visually with clear sections, good touch targets, and appropriate Spanish copy. However, the auto-apply-on-tap pattern inherited from `FilterSortSheet` (inventory) does not fit a date-range workflow. The custom-date flow forces a dopamine-destroying open-close-open-pick dance. This feels like a design pattern applied without considering whether the surface type fits it — the movements screen is an **Operate** surface where efficiency matters, and the current flow is anything but efficient.

**Deterministic scan:** No automated design-rule violations detected (Dart/Flutter file).

## Overall Impression

The filter sheet looks good and the individual component craftsmanship is high. But the interaction model is fighting the user. Every tap closes the sheet, which is fine for a single toggle but devastating for a multi-parameter filter that involves a date range picker. The user must open the sheet → tap tipo → sheet closes → open sheet again → tap Personalizado → sheet closes → date picker opens. This is at least 3 more steps than necessary.

The single biggest opportunity: **keep the sheet open while configuring, embed the date picker inline.**

## What's Working

1. **Visual design is clean.** Good iconography, proper spacing, clear section headers, adequate touch targets (56dp), and nice micro-animation on the drag handle.
2. **Filter state chip.** The "Mostrando: Esta semana (..." label above the feed is exactly what users need to stay oriented.
3. **Active filter badge.** The counter in the sheet header and the `InputChip` in the screen give clear feedback about what's active.

## Priority Issues

### [P0] Flow breakage: custom date selection forces sheet to close and re-open
**What:** Tapping "Personalizado" closes the sheet via `_onCustomRangeTapped()` → pops the sheet → `onCustomRangeRequested` sets `rango=personalizado` (no dates) → `.then` callback opens `_openCustomDatePicker()`. This is a fragile multi-act play that relies on state transitions across two widgets.
**Why it matters:** If the date picker is dismissed via system Back (not Cancelar), `rango` was already set to `personalizado` with no dates. The `fechaInicio` getter silently falls back to `startOfToday`, showing today's data under a "Personalizado" label — the user gets wrong results with no indication.
**Fix:** Embed the date range picker inside the sheet. Keep the sheet open. Add an Apply/Cancel footer.
**Suggested command:** `$impeccable shape`

### [P1] Auto-close on every tile selection prevents multi-filter configuration
**What:** Every `_FilterListTile.onTap` calls `_applyFilters()` → `Navigator.pop()`. The user can only set one parameter per sheet-open.
**Why it matters:** To set "Solo Entradas" + "Últimos 30 días", the user opens the sheet → taps "Solo Entradas" → sheet closes → opens sheet again → taps "Últimos 30 días" → sheet closes. This is 2x the work.
**Fix:** Remove `_applyFilters()` from individual tile handlers. Let tiles update local state only. Add an "Aplicar" button that commits all changes at once.
**Suggested command:** `$impeccable shape`

### [P1] Partial filter state during custom-date transition
**What:** `onCustomRangeRequested` sets `rango=personalizado` but does NOT set `fechaInicioCustom`/`fechaFinCustom`. Between sheet-close and date-picker-complete, the state is `rango=personalizado` with null custom dates.
**Why it matters:** `MovimientosFilterState.fechaInicio` and `fechaFin` getters have fallbacks to `startOfToday`/`startOfTomorrow` when custom dates are null. So the filter silently shows today's data under a "Personalizado" label — misleading.
**Fix:** Eliminate the transitional state by keeping the date picker inside the sheet (same fix as P0).
**Suggested command:** `$impeccable shape`

### [P2] Date formatting logic duplicated
**What:** Both `movimiento_filter_sheet.dart:439-444` and `movimientos_screen.dart:255-262` have identical `_formatDate`/`months` arrays.
**Why it matters:** Maintainability — a format change requires editing two files.
**Fix:** Extract to a shared utility or use `DateFormat` from `intl` package (already likely in the project).
**Suggested command:** `$impeccable distill`

### [P2] No feedback when date picker is cancelled
**What:** If the user cancels the date picker (via "Cancelar" or system Back), the filter silently resets to "Hoy" (line 250). No snackbar, no toast, no explanation.
**Why it matters:** The user might not notice the filter changed, especially if they had a different rango selected before tapping "Personalizado".
**Fix:** Show a brief snackbar: "Rango personalizado cancelado. Filtro restaurado."
**Suggested command:** `$impeccable harden`

## Persona Red Flags

### Alex (Power User)
- **No batch configuration**: Alex must open-close the sheet multiple times to set tipo + custom date range. This is infuriating for someone who wants to get in, filter, and get out in under 30 seconds.
- **No keyboard shortcuts**: Navigation is all taps; no Esc to close, no Enter to apply.
- **Double-open pattern**: The current flow requires at minimum 2 sheet opens + 1 date picker interaction for a combined filter. Alex abandons.

### Jordan (First-Timer)
- **"Personalizado" is ambiguous**: No explanation of what happens after tapping. Jordan sees "Personalizado" but doesn't know it opens a date picker after the sheet closes — confusing sequence.
- **Sheet disappears on every tap**: Jordan taps "Solo Entradas" and the sheet vanishes. They think something broke. They tentatively tap the filter button again to see if it's still there.
- **No confirmation of success**: After the whole custom-date dance, if Jordan cancels, the filter silently resets. They don't know what happened.

### Riley (Stress Tester)
- **Dismiss date picker with Back gesture**: Riley dismisses the date picker with system Back (not Cancelar). The state transitions through `rango=personalizado` → date picker cancelled → reset to `hoy`. Riley notes the flicker and reports "the filter resets itself."
- **Select Personalizado → cancel → reopen sheet**: Riley opens the sheet, sees "Personalizado" was active, taps another rango, then taps "Personalizado" again, cancels, and checks whether the original rango or "Personalizado" wins. The answer depends on timing.
- **Rapid double-tap**: Riley double-taps "Personalizado" before the sheet closes. The `onCustomRangeRequested` fires twice, setting state twice.

## Minor Observations

- The `_activeFiltersCount` counts `rango != hoy` but doesn't distinguish between a preset (semana/mes) and a custom range. Both count as "1 filter active."
- `_CustomRangeTile` uses a 4px left border for selected state — consistent with other tiles, but it's the only tile that also shows a check icon. Slight inconsistency in selected-state encoding.
- The `_rangoLabel` helper in `movimientos_screen.dart` uses `compactDateFormatter` for day headers but custom format for the label — inconsistent date formatting.

## Questions to Consider

- "What if the filter sheet never closed until the user explicitly pressed 'Aplicar' or 'Cancelar'?"
- "Does the date range picker need to be a system dialog, or could it be an inline calendar embedded in the sheet?"
- "What would the confident version of this flow look like — one surface, one decision, one tap to apply?"

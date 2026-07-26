---
target: pantalla Resumen (admin dashboard)
total_score: 21
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 2
timestamp: 2026-07-25T22-43-43Z
slug: features-resumen-presentation-resumen-screen-dart
---
# Design Critique: Resumen Screen

Method: dual-agent (A: ses_0648f0502ffeXmI77n40nKZUBM · B: ses_0648ef179ffeVTvhQo1ivKqfpU)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 1 | No loading state, no error state, no skeleton. Synchronous provider crashes silently on data errors |
| 2 | Match System / Real World | 3 | Spanish copy is natural but 'Top productos' is Spanglish |
| 3 | User Control and Freedom | 3 | Period selector works, refresh works. No undo on navigation |
| 4 | Consistency and Standards | 3 | _HeroStatCard uses Container while other cards use Card |
| 5 | Error Prevention | 1 | No defensive zero-data handling. datos.reduce() at line 698 crashes on empty list |
| 6 | Recognition Rather Than Recall | 3 | Alert cards show actionable context. Sparkline lacks tap-to-inspect |
| 7 | Flexibility and Efficiency | 2 | No power-user shortcuts. Top products capped at 5 silently |
| 8 | Aesthetic and Minimalist Design | 3 | Clean spacing. Sparkline painter over-engineered for glanceable dashboard |
| 9 | Error Recovery | 1 | Zero error states. Data crash = blank screen |
| 10 | Help and Documentation | 1 | No contextual help. Domain jargon unexplained |
| **Total** | | **21/40** | **Acceptable** |

## Design Specificity Verdict

Generic. Could be any inventory app. No motorcycle-specific insights, category grouping, or seasonal context.

## Overall Impression

Solid token system, elegant alert cards, premium sparkline. But reads as a template, not a dashboard for a specific business.

## What's Working

1. Token system discipline (AppSpacing, AppRadii, AppAlphas, AppShadows)
2. Alert card duality (_AlertaCard:593-684)
3. Sparkline craft (_SparklinePainterMejorado:940-1162)

## Priority Issues

### P0 — No loading/error state
datosResumenProvider is synchronous. Crash = blank screen with no recovery.

### P0 — Sparkline period mismatch
Always shows 7 days regardless of period selector. Breaks user trust.

### P1 — Zero accessibility semantics
1162 lines, zero Semantics widgets. Invisible to screen readers.

### P1 — Dead code
_Sparkline widget (916-937) unused. stat_card.dart and stock_badge.dart imported but unreferenced.

### P2 — No delta/comparison on hero stats
Absolute numbers without trend context. Shop owner can't tell if today is better or worse.

## Persona Red Flags

### Jordan (First-timer)
No onboarding, no explanation of domain terms, sparkline unintelligible.

### Sam (Accessibility)
All custom widgets invisible to screen readers. No semantic labels.

### Riley (Stress tester)
No visual feedback on refresh. No stale-data indicator. Rapid period switching causes jank.

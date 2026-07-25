---
description: Auditoria tecnica: accesibilidad, performance, responsive, theming, integridad
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run a technical audit.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/audit.md from the skill (or reference/audit.native.md for iOS/Android)
3. Run the diagnostic scan across 5 dimensions, scoring each 0-4:
   - Accessibility (WCAG compliance, ARIA, keyboard nav, contrast)
   - Performance (layout thrashing, expensive animations, bundle size)
   - Theming (design tokens, dark mode, consistency)
   - Responsive Design (mobile, touch targets, breakpoints)
   - Implementation Integrity (run detector: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\detect.mjs" --json <target>`)
4. Generate the Audit Health Score table (total /20)
5. Document all issues by severity (P0-P3) with location, category, impact, and recommended command
6. Identify systemic patterns and positive findings
7. Present recommended actions in priority order

Target: $ARGUMENTS (file path, directory, or URL to audit)
